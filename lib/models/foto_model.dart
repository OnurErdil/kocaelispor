// lib/models/foto_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Foto {
  final String id;
  final String url;
  final String baslik;
  final String? aciklama;
  final String kategori;
  final DateTime tarih;
  final String? fotografci;
  final List<String> etiketler;
  final int begeniSayisi;

  Foto({
    required this.id,
    required this.url,
    required this.baslik,
    this.aciklama,
    required this.kategori,
    required this.tarih,
    this.fotografci,
    this.etiketler = const [],
    this.begeniSayisi = 0,
  });

  // Firestore'dan Foto nesnesi oluştur
  factory Foto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Foto(
      id: doc.id,
      url: data['url'] ?? '',
      baslik: data['baslik'] ?? '',
      aciklama: data['aciklama'],
      kategori: data['kategori'] ?? 'Genel',
      tarih: (data['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fotografci: data['fotografci'],
      etiketler: List<String>.from(data['etiketler'] ?? []),
      begeniSayisi: data['begeniSayisi'] ?? 0,
    );
  }

  // Firestore'a göndermek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'baslik': baslik,
      'aciklama': aciklama,
      'kategori': kategori,
      'tarih': Timestamp.fromDate(tarih),
      'fotografci': fotografci,
      'etiketler': etiketler,
      'begeniSayisi': begeniSayisi,
    };
  }

  // Tarihi güzel formatta göster
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(tarih);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${tarih.day}/${tarih.month}/${tarih.year}';
    }
  }

  // Kategori rengini al
  static Color getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'maç':
      case 'mac':
        return const Color(0xFF4CAF50); // Yeşil
      case 'antrenman':
        return const Color(0xFFFF9800); // Turuncu
      case 'taraftar':
        return const Color(0xFFE91E63); // Pembe
      case 'stadyum':
        return const Color(0xFF2196F3); // Mavi
      case 'oyuncular':
        return const Color(0xFF9C27B0); // Mor
      case 'kutlama':
        return const Color(0xFFFFC107); // Sarı
      default:
        return const Color(0xFF607D8B); // Gri
    }
  }

  // Kategori ikonu al
  static IconData getKategoriIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'maç':
      case 'mac':
        return Icons.sports_soccer;
      case 'antrenman':
        return Icons.fitness_center;
      case 'taraftar':
        return Icons.people;
      case 'stadyum':
        return Icons.stadium;
      case 'oyuncular':
        return Icons.person;
      case 'kutlama':
        return Icons.celebration;
      default:
        return Icons.photo;
    }
  }
}