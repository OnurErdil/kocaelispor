// lib/models/haber_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // ✅ BU SATIRI EKLEDİK

class Haber {
  final String id;
  final String baslik;
  final String icerik;
  final String? resimUrl;
  final String kategori;
  final DateTime tarih;
  final String? yazar;
  final bool onemli;
  final List<String> etiketler;

  Haber({
    required this.id,
    required this.baslik,
    required this.icerik,
    this.resimUrl,
    required this.kategori,
    required this.tarih,
    this.yazar,
    this.onemli = false,
    this.etiketler = const [],
  });

  // Firestore'dan Haber nesnesi oluştur
  factory Haber.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Haber(
      id: doc.id,
      baslik: data['baslik'] ?? '',
      icerik: data['icerik'] ?? '',
      resimUrl: data['resimUrl'],
      kategori: data['kategori'] ?? 'Genel',
      tarih: (data['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
      yazar: data['yazar'],
      onemli: data['onemli'] ?? false,
      etiketler: List<String>.from(data['etiketler'] ?? []),
    );
  }

  // Firestore'a göndermek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'baslik': baslik,
      'icerik': icerik,
      'resimUrl': resimUrl,
      'kategori': kategori,
      'tarih': Timestamp.fromDate(tarih),
      'yazar': yazar,
      'onemli': onemli,
      'etiketler': etiketler,
    };
  }

  // Tarihi güzel formatta göster
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(tarih);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${tarih.day}/${tarih.month}/${tarih.year}';
    }
  }

  // Kategori rengini al
  static getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'transfer':
        return const Color(0xFF2196F3); // Mavi
      case 'maç':
      case 'mac':
        return const Color(0xFF4CAF50); // Yeşil
      case 'antrenman':
        return const Color(0xFFFF9800); // Turuncu
      case 'yönetim':
      case 'yonetim':
        return const Color(0xFF9C27B0); // Mor
      case 'taraftar':
        return const Color(0xFFE91E63); // Pembe
      default:
        return const Color(0xFF607D8B); // Gri
    }
  }

  // Kategori ikonu al
  static getKategoriIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'transfer':
        return Icons.swap_horiz;
      case 'maç':
      case 'mac':
        return Icons.sports_soccer;
      case 'antrenman':
        return Icons.fitness_center;
      case 'yönetim':
      case 'yonetim':
        return Icons.business;
      case 'taraftar':
        return Icons.people;
      default:
        return Icons.article;
    }
  }
}