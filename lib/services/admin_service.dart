// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin e-postaları (manuel olarak belirlenen)
  static const List<String> _adminEmails = [
    'admin@kocaelispor.com',
    'yonetici@kocaelispor.com',
    'onurerdil1982@gmail.com',  // Buraya admin e-postalarını ekleyin
  ];

  /// Kullanıcının admin olup olmadığını kontrol et
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // E-posta kontrolü
      if (_adminEmails.contains(user.email?.toLowerCase())) {
        return true;
      }

      // Firestore'dan kontrol et
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['role'] == 'admin' || userData['isAdmin'] == true;
    } catch (e) {
      print('Admin kontrol hatası: $e');
      return false;
    }
  }

  /// Kullanıcıyı admin yap
  static Future<bool> makeUserAdmin(String email) async {
    try {
      // E-posta ile kullanıcıyı bul
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // İlk bulunan kullanıcıyı admin yap
      final userDoc = querySnapshot.docs.first;
      await userDoc.reference.update({
        'role': 'admin',
        'isAdmin': true,
        'adminSince': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Admin yapma hatası: $e');
      return false;
    }
  }

  /// Admin yetkisini kaldır
  static Future<bool> removeAdminRole(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userDoc = querySnapshot.docs.first;
      await userDoc.reference.update({
        'role': 'user',
        'isAdmin': false,
        'adminSince': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      print('Admin kaldırma hatası: $e');
      return false;
    }
  }

  /// Tüm adminleri listele
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Admin listesi hatası: $e');
      return [];
    }
  }

  /// Admin aktivitesi kaydet
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
        'adminId': user.uid,
        'adminEmail': user.email,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': 'Flutter Mobile App',
      });
    } catch (e) {
      print('Admin log hatası: $e');
    }
  }

  /// Admin istatistikleri
  static Future<Map<String, int>> getAdminStats() async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').get(),
        _firestore.collection('haberler').get(),
        _firestore.collection('Takım').get(),
        _firestore.collection('fixture').get(),
        _firestore.collection('fotograflar').get(),
      ]);

      return {
        'totalUsers': results[0].docs.length,
        'totalNews': results[1].docs.length,
        'totalPlayers': results[2].docs.length,
        'totalMatches': results[3].docs.length,
        'totalPhotos': results[4].docs.length,
      };
    } catch (e) {
      print('İstatistik hatası: $e');
      return {
        'totalUsers': 0,
        'totalNews': 0,
        'totalPlayers': 0,
        'totalMatches': 0,
        'totalPhotos': 0,
      };
    }
  }

  /// Kullanıcı kaydında admin kontrolü
  static Future<void> setupUserOnRegister(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);

      // Kullanıcı zaten varsa güncelleme
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) return;

      // Yeni kullanıcı için varsayılan rol
      final isAdmin = _adminEmails.contains(user.email?.toLowerCase());

      await userDoc.set({
        'email': user.email?.toLowerCase(),
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'role': isAdmin ? 'admin' : 'user',
        'isAdmin': isAdmin,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        if (isAdmin) 'adminSince': FieldValue.serverTimestamp(),
      });

      if (isAdmin) {
        await logAdminActivity(
          action: 'AUTO_ADMIN_ASSIGNED',
          targetType: 'USER',
          targetId: user.uid,
          details: {'email': user.email},
        );
      }
    } catch (e) {
      print('Kullanıcı setup hatası: $e');
    }
  }

  /// Admin paneli erişim kontrolü
  static Future<bool> canAccessAdminPanel() async {
    final isAdmin = await isCurrentUserAdmin();
    if (isAdmin) {
      await logAdminActivity(
        action: 'ADMIN_PANEL_ACCESS',
        targetType: 'SYSTEM',
      );
    }
    return isAdmin;
  }

  /// Bulk operasyonlar için admin kontrolü
  static Future<bool> canPerformBulkOperation() async {
    return await isCurrentUserAdmin();
  }

  /// Super admin kontrolü (sadece e-posta listesindekiler)
  static Future<bool> isSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return _adminEmails.contains(user.email?.toLowerCase());
  }
}