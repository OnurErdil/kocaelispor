// lib/services/statistics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Toplam taraftar sayısı
  static Future<int> getTotalUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Kullanıcı sayısı alınamadı: $e');
      return 0;
    }
  }

  // Toplam forum mesaj sayısı
  static Future<int> getTotalForumMessages() async {
    try {
      final snapshot = await _firestore.collection('forum_mesajlari').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Mesaj sayısı alınamadı: $e');
      return 0;
    }
  }

  // Toplam takım oyuncusu sayısı
  static Future<int> getTotalPlayers() async {
    try {
      final snapshot = await _firestore.collection('Takım').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Oyuncu sayısı alınamadı: $e');
      return 0;
    }
  }

  // Bugünkü mesaj sayısı
  static Future<int> getTodayMessages() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('forum_mesajlari')
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('tarih', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Bugünkü mesaj sayısı alınamadı: $e');
      return 0;
    }
  }

  // En aktif taraftar (en çok mesaj gönderen)
  static Future<Map<String, dynamic>?> getMostActiveUser() async {
    try {
      final snapshot = await _firestore.collection('forum_mesajlari').get();

      if (snapshot.docs.isEmpty) return null;

      // Kullanıcıların mesaj sayısını say
      Map<String, int> userMessageCount = {};
      Map<String, String> userNames = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['gonderenId'] as String?;
        final userName = data['gonderenAd'] as String?;

        if (userId != null) {
          userMessageCount[userId] = (userMessageCount[userId] ?? 0) + 1;
          if (userName != null) {
            userNames[userId] = userName;
          }
        }
      }

      // En çok mesaj göndereni bul
      String? mostActiveUserId;
      int maxMessages = 0;

      userMessageCount.forEach((userId, count) {
        if (count > maxMessages) {
          maxMessages = count;
          mostActiveUserId = userId;
        }
      });

      if (mostActiveUserId != null) {
        return {
          'userId': mostActiveUserId,
          'name': userNames[mostActiveUserId] ?? 'Anonim Taraftar',
          'messageCount': maxMessages,
        };
      }

      return null;
    } catch (e) {
      print('En aktif kullanıcı alınamadı: $e');
      return null;
    }
  }

  // Tüm istatistikleri al
  static Future<Map<String, dynamic>> getAllStatistics() async {
    try {
      final results = await Future.wait([
        getTotalUsers(),
        getTotalForumMessages(),
        getTotalPlayers(),
        getTodayMessages(),
        getMostActiveUser(),
      ]);

      return {
        'totalUsers': results[0] as int,
        'totalMessages': results[1] as int,
        'totalPlayers': results[2] as int,
        'todayMessages': results[3] as int,
        'mostActiveUser': results[4] as Map<String, dynamic>?,
      };
    } catch (e) {
      print('İstatistikler alınamadı: $e');
      return {
        'totalUsers': 0,
        'totalMessages': 0,
        'totalPlayers': 0,
        'todayMessages': 0,
        'mostActiveUser': null,
      };
    }
  }

  // Sayıyı güzel formatta göster (1000 -> 1K)
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}