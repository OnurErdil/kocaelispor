// lib/services/admin_service.dart - Düzeltilmiş Versiyon

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının admin olup olmadığını kontrol et (hem string hem boolean destekler)
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;

      // Hem boolean hem string destekle
      final adminValue = userData['isAdmin'];

      // Boolean kontrolü
      if (adminValue is bool) {
        return adminValue;
      }

      // String kontrolü ("true", "True", "TRUE" vs.)
      if (adminValue is String) {
        return adminValue.toLowerCase().trim() == 'true';
      }

      // Role kontrolü (ekstra güvenlik)
      final roleValue = userData['role'];
      if (roleValue is String) {
        return roleValue.toLowerCase().trim() == 'admin';
      }

      return false;
    } catch (e) {
      print('Admin kontrolü hatası: $e');
      return false;
    }
  }

  // Admin paneline erişim kontrolü (ek güvenlik)
  static Future<bool> canAccessAdminPanel() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Email doğrulaması kontrolü
      if (!user.emailVerified) {
        print('E-posta doğrulanmamış: ${user.email}');
        return false;
      }

      // Admin kontrolü
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        print('Kullanıcı admin değil: ${user.email}');
        return false;
      }

      // Admin panel erişimini logla
      await logAdminActivity(
        action: 'ADMIN_PANEL_ACCESS',
        targetType: 'SYSTEM',
        targetId: 'admin_panel',
      );

      return true;
    } catch (e) {
      print('Admin panel erişim kontrolü hatası: $e');
      return false;
    }
  }

  // Admin istatistiklerini getir
  static Future<Map<String, int>> getAdminStats() async {
    try {
      final Map<String, int> stats = {};

      // Kullanıcı sayısı
      final usersSnapshot = await _firestore.collection('users').get();
      stats['totalUsers'] = usersSnapshot.docs.length;

      // Haber sayısı
      final newsSnapshot = await _firestore.collection('haberler').get();
      stats['totalNews'] = newsSnapshot.docs.length;

      // Oyuncu sayısı
      final playersSnapshot = await _firestore.collection('Takım').get();
      stats['totalPlayers'] = playersSnapshot.docs.length;

      // Maç sayısı
      final matchesSnapshot = await _firestore.collection('maclar').get();
      stats['totalMatches'] = matchesSnapshot.docs.length;

      return stats;
    } catch (e) {
      print('İstatistik yükleme hatası: $e');
      return {
        'totalUsers': 0,
        'totalNews': 0,
        'totalPlayers': 0,
        'totalMatches': 0,
      };
    }
  }

  // Kullanıcıyı admin yap
  static Future<bool> makeUserAdmin(String email) async {
    try {
      // E-posta ile kullanıcı bul
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (usersQuery.docs.isEmpty) {
        print('Kullanıcı bulunamadı: $email');
        return false;
      }

      final userDoc = usersQuery.docs.first;

      // Admin yap (hem boolean hem string güncelle)
      await userDoc.reference.update({
        'isAdmin': true,  // Boolean
        'role': 'admin',  // String (ek güvenlik)
        'adminSince': FieldValue.serverTimestamp(),
      });

      print('Kullanıcı admin yapıldı: $email');
      return true;
    } catch (e) {
      print('Admin yapma hatası: $e');
      return false;
    }
  }

  // Admin yetkisini kaldır
  static Future<bool> removeAdminRole(String email) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (usersQuery.docs.isEmpty) {
        print('Kullanıcı bulunamadı: $email');
        return false;
      }

      final userDoc = usersQuery.docs.first;

      // Admin yetkisini kaldır
      await userDoc.reference.update({
        'isAdmin': false,
        'role': 'user',
        'adminRemovedAt': FieldValue.serverTimestamp(),
      });

      print('Admin yetkisi kaldırıldı: $email');
      return true;
    } catch (e) {
      print('Admin yetkisi kaldırma hatası: $e');
      return false;
    }
  }

  // Admin aktivitesini logla
  static Future<void> logAdminActivity({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('admin_logs').add({
        'action': action,
        'adminId': user.uid,
        'adminEmail': user.email,
        'targetType': targetType,
        'targetId': targetId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Admin aktivitesi loglandı: $action');
    } catch (e) {
      print('Log kaydetme hatası: $e');
    }
  }

  // Kullanıcı kaydında admin kontrolü yap (yeni kullanıcılar için)
  static Future<void> setupUserOnRegister(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      // Kullanıcı daha önce kaydedilmiş mi kontrol et
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Yeni kullanıcı, varsayılan olarak admin değil
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'isAdmin': false, // Boolean olarak false
          'role': 'user',   // String olarak user
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        print('Yeni kullanıcı kaydedildi: ${user.email}');
      } else {
        // Mevcut kullanıcı, sadece son giriş zamanını güncelle
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        print('Kullanıcı girişi güncellendi: ${user.email}');
      }
    } catch (e) {
      print('Kullanıcı setup hatası: $e');
    }
  }

  // Debug: Kullanıcının admin durumunu kontrol et
  static Future<void> debugCheckAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('🚫 Kullanıcı giriş yapmamış');
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('🚫 Kullanıcı dokümanı bulunamadı');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      print('📋 Kullanıcı Bilgileri:');
      print('   Email: ${user.email}');
      print('   UID: ${user.uid}');
      print('   isAdmin: ${userData['isAdmin']} (${userData['isAdmin'].runtimeType})');
      print('   role: ${userData['role']}');

      final isAdmin = await isCurrentUserAdmin();
      print('   Admin Kontrolü: $isAdmin');

    } catch (e) {
      print('❌ Debug kontrol hatası: $e');
    }
  }
}