// lib/models/foto_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Foto {
  final String id;
  final String url;
  final String baslik;
  final String? aciklama;
  final String kategori;
  final String? fotografci;
  final DateTime tarih;
  final List<String> etiketler;
  final int begeniSayisi;

  Foto({
    required this.id,
    required this.url,
    required this.baslik,
    this.aciklama,
    required this.kategori,
    this.fotografci,
    required this.tarih,
    required this.etiketler,
    required this.begeniSayisi,
  });

  // Firestore'dan Foto objesi oluştur
  factory Foto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Foto(
      id: doc.id,
      url: data['url'] ?? '',
      baslik: data['baslik'] ?? 'Başlık Yok',
      aciklama: data['aciklama'],
      kategori: data['kategori'] ?? 'Genel',
      fotografci: data['fotografci'],
      tarih: (data['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
      etiketler: List<String>.from(data['etiketler'] ?? []),
      begeniSayisi: data['begeniSayisi'] ?? 0,
    );
  }

  // Firestore'a kaydetmek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'baslik': baslik,
      'aciklama': aciklama,
      'kategori': kategori,
      'fotografci': fotografci,
      'tarih': Timestamp.fromDate(tarih),
      'etiketler': etiketler,
      'begeniSayisi': begeniSayisi,
    };
  }

  // Formatlanmış tarih
  String get formattedDate {
    return "${tarih.day}.${tarih.month}.${tarih.year}";
  }

  // Kategori rengini döndür
  static Color getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'maç':
        return Colors.red.shade600;
      case 'antrenman':
        return Colors.blue.shade600;
      case 'taraftar':
        return Colors.orange.shade600;
      case 'stadyum':
        return Colors.purple.shade600;
      case 'oyuncular':
        return Colors.green.shade600;
      case 'kutlama':
        return Colors.pink.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Kategori ikonunu döndür
  static IconData getKategoriIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'maç':
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

  // Kopyalama metodu (güncelleme için)
  Foto copyWith({
    String? url,
    String? baslik,
    String? aciklama,
    String? kategori,
    String? fotografci,
    DateTime? tarih,
    List<String>? etiketler,
    int? begeniSayisi,
  }) {
    return Foto(
      id: id,
      url: url ?? this.url,
      baslik: baslik ?? this.baslik,
      aciklama: aciklama ?? this.aciklama,
      kategori: kategori ?? this.kategori,
      fotografci: fotografci ?? this.fotografci,
      tarih: tarih ?? this.tarih,
      etiketler: etiketler ?? this.etiketler,
      begeniSayisi: begeniSayisi ?? this.begeniSayisi,
    );
  }

  @override
  String toString() {
    return 'Foto{id: $id, baslik: $baslik, kategori: $kategori}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Foto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}