// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının admin olup olmadığını kontrol et
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['isAdmin'] == true;
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
      final playersSnapshot = await _firestore.collection('oyuncular').get();
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

      // Admin yetkisi ver
      await userDoc.reference.update({'isAdmin': true});

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

      // Admin yetkisini kaldır
      await userDoc.reference.update({'isAdmin': false});

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
          'isAdmin': false, // Varsayılan olarak admin değil
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

      // Admin panel erişimi logla (admin ise)
      final userData = docSnapshot.exists ? docSnapshot.data() as Map<String, dynamic> : {'isAdmin': false};
      if (userData['isAdmin'] == true) {
        await logAdminActivity(
          action: 'ADMIN_LOGIN',
          targetType: 'SYSTEM',
          targetId: user.uid,
        );
      }
    } catch (e) {
      print('Kullanıcı kurulum hatası: $e');
    }
  }

  // İlk admin kullanıcıyı oluştur (geliştirme amaçlı)
  static Future<void> createFirstAdmin(String email) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final userDoc = usersQuery.docs.first;
        await userDoc.reference.update({'isAdmin': true});

        await logAdminActivity(
          action: 'FIRST_ADMIN_CREATED',
          targetType: 'USER',
          targetId: email,
        );

        print('İlk admin oluşturuldu: $email');
      } else {
        print('Kullanıcı bulunamadı: $email');
      }
    } catch (e) {
      print('İlk admin oluşturma hatası: $e');
    }
  }

  // Tüm adminleri listele
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final adminQuery = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      return adminQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Admin listesi yükleme hatası: $e');
      return [];
    }
  }

  // Admin loglarını temizle (eski logları sil)
  static Future<void> cleanOldLogs({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final oldLogsQuery = await _firestore
          .collection('admin_logs')
          .where('timestamp', isLessThan: cutoffTimestamp)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldLogsQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('${oldLogsQuery.docs.length} eski log temizlendi');
    } catch (e) {
      print('Log temizleme hatası: $e');
    }
  }

  // Kullanıcı sayısı istatistikleri
  static Future<Map<String, int>> getUserStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      int totalUsers = usersSnapshot.docs.length;
      int adminUsers = usersSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isAdmin'] == true;
      }).length;

      return {
        'totalUsers': totalUsers,
        'adminUsers': adminUsers,
        'regularUsers': totalUsers - adminUsers,
      };
    } catch (e) {
      print('Kullanıcı istatistik hatası: $e');
      return {'totalUsers': 0, 'adminUsers': 0, 'regularUsers': 0};
    }
  }
}