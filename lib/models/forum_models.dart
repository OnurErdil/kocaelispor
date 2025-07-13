// lib/models/forum_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Forum Kategorisi Model
class ForumKategori {
  final String id;
  final String ad;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  final int sira;
  final bool aktif;
  final DateTime olusturmaTarihi;
  final int konuSayisi;
  final int mesajSayisi;
  final DateTime? sonAktivite;

  const ForumKategori({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.ikon,
    required this.renk,
    required this.sira,
    this.aktif = true,
    required this.olusturmaTarihi,
    this.konuSayisi = 0,
    this.mesajSayisi = 0,
    this.sonAktivite,
  });

  factory ForumKategori.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ForumKategori(
      id: doc.id,
      ad: data['ad'] ?? '',
      aciklama: data['aciklama'] ?? '',
      ikon: _parseIcon(data['ikon']),
      renk: Color(data['renk'] ?? 0xFF4CAF50),
      sira: data['sira'] ?? 0,
      aktif: data['aktif'] ?? true,
      olusturmaTarihi: (data['olusturmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      konuSayisi: data['konuSayisi'] ?? 0,
      mesajSayisi: data['mesajSayisi'] ?? 0,
      sonAktivite: (data['sonAktivite'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'aciklama': aciklama,
      'ikon': ikon.codePoint,
      'renk': renk.value,
      'sira': sira,
      'aktif': aktif,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
      'konuSayisi': konuSayisi,
      'mesajSayisi': mesajSayisi,
      'sonAktivite': sonAktivite != null ? Timestamp.fromDate(sonAktivite!) : null,
    };
  }

  static IconData _parseIcon(dynamic iconData) {
    if (iconData is int) {
      return IconData(iconData, fontFamily: 'MaterialIcons');
    }
    return Icons.forum; // Varsayılan ikon
  }
}

// Forum Konusu Model
class ForumKonu {
  final String id;
  final String baslik;
  final String? aciklama;
  final String kategoriId;
  final String olusturanId;
  final String olusturanAd;
  final String? olusturanFoto;
  final DateTime olusturmaTarihi;
  final bool sabitlenmis;
  final bool kilitli;
  final String? etiket; // 'hot', 'new', 'important' gibi
  final int mesajSayisi;
  final int goruntulemeSayisi;
  final DateTime? sonMesajTarihi;
  final String? sonMesajGonderenAd;

  const ForumKonu({
    required this.id,
    required this.baslik,
    this.aciklama,
    required this.kategoriId,
    required this.olusturanId,
    required this.olusturanAd,
    this.olusturanFoto,
    required this.olusturmaTarihi,
    this.sabitlenmis = false,
    this.kilitli = false,
    this.etiket,
    this.mesajSayisi = 0,
    this.goruntulemeSayisi = 0,
    this.sonMesajTarihi,
    this.sonMesajGonderenAd,
  });

  factory ForumKonu.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ForumKonu(
      id: doc.id,
      baslik: data['baslik'] ?? '',
      aciklama: data['aciklama'],
      kategoriId: data['kategoriId'] ?? '',
      olusturanId: data['olusturanId'] ?? '',
      olusturanAd: data['olusturanAd'] ?? 'Anonim',
      olusturanFoto: data['olusturanFoto'],
      olusturmaTarihi: (data['olusturmaTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sabitlenmis: data['sabitlenmis'] ?? false,
      kilitli: data['kilitli'] ?? false,
      etiket: data['etiket'],
      mesajSayisi: data['mesajSayisi'] ?? 0,
      goruntulemeSayisi: data['goruntulemeSayisi'] ?? 0,
      sonMesajTarihi: (data['sonMesajTarihi'] as Timestamp?)?.toDate(),
      sonMesajGonderenAd: data['sonMesajGonderenAd'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baslik': baslik,
      'aciklama': aciklama,
      'kategoriId': kategoriId,
      'olusturanId': olusturanId,
      'olusturanAd': olusturanAd,
      'olusturanFoto': olusturanFoto,
      'olusturmaTarihi': Timestamp.fromDate(olusturmaTarihi),
      'sabitlenmis': sabitlenmis,
      'kilitli': kilitli,
      'etiket': etiket,
      'mesajSayisi': mesajSayisi,
      'goruntulemeSayisi': goruntulemeSayisi,
      'sonMesajTarihi': sonMesajTarihi != null ? Timestamp.fromDate(sonMesajTarihi!) : null,
      'sonMesajGonderenAd': sonMesajGonderenAd,
    };
  }

  // Etiket rengi
  Color get etiketRengi {
    switch (etiket) {
      case 'hot':
        return Colors.red;
      case 'new':
        return Colors.green;
      case 'important':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Etiket metni
  String get etiketMetni {
    switch (etiket) {
      case 'hot':
        return 'Popüler';
      case 'new':
        return 'Yeni';
      case 'important':
        return 'Önemli';
      default:
        return '';
    }
  }
}

// Forum Mesajı Model
class ForumMesaj {
  final String id;
  final String icerik;
  final String konuId;
  final String gonderenId;
  final String gonderenAd;
  final String? gonderenFoto;
  final DateTime tarih;
  final bool duzenlendiMi;
  final DateTime? duzenlenmeTarihi;
  final String? yanitlandigiMesajId; // Reply sistemi için
  final List<String> begenenler;
  final List<String> reactionlar; // '👍', '❤️', '⚽' gibi
  final Map<String, int> reactionSayilari;

  const ForumMesaj({
    required this.id,
    required this.icerik,
    required this.konuId,
    required this.gonderenId,
    required this.gonderenAd,
    this.gonderenFoto,
    required this.tarih,
    this.duzenlendiMi = false,
    this.duzenlenmeTarihi,
    this.yanitlandigiMesajId,
    this.begenenler = const [],
    this.reactionlar = const [],
    this.reactionSayilari = const {},
  });

  factory ForumMesaj.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ForumMesaj(
      id: doc.id,
      icerik: data['icerik'] ?? '',
      konuId: data['konuId'] ?? '',
      gonderenId: data['gonderenId'] ?? '',
      gonderenAd: data['gonderenAd'] ?? 'Anonim',
      gonderenFoto: data['gonderenFoto'],
      tarih: (data['tarih'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duzenlendiMi: data['duzenlendiMi'] ?? false,
      duzenlenmeTarihi: (data['duzenlenmeTarihi'] as Timestamp?)?.toDate(),
      yanitlandigiMesajId: data['yanitlandigiMesajId'],
      begenenler: List<String>.from(data['begenenler'] ?? []),
      reactionlar: List<String>.from(data['reactionlar'] ?? []),
      reactionSayilari: Map<String, int>.from(data['reactionSayilari'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icerik': icerik,
      'konuId': konuId,
      'gonderenId': gonderenId,
      'gonderenAd': gonderenAd,
      'gonderenFoto': gonderenFoto,
      'tarih': Timestamp.fromDate(tarih),
      'duzenlendiMi': duzenlendiMi,
      'duzenlenmeTarihi': duzenlenmeTarihi != null ? Timestamp.fromDate(duzenlenmeTarihi!) : null,
      'yanitlandigiMesajId': yanitlandigiMesajId,
      'begenenler': begenenler,
      'reactionlar': reactionlar,
      'reactionSayilari': reactionSayilari,
    };
  }

  // Toplam beğeni sayısı
  int get toplamBegeni => begenenler.length;

  // Toplam reaction sayısı
  int get toplamReaction => reactionSayilari.values.fold(0, (sum, count) => sum + count);
}

// Varsayılan Kategoriler
class VarsayilanKategoriler {
  static List<ForumKategori> getVarsayilanlar() {
    return [
      ForumKategori(
        id: 'genel',
        ad: 'Genel Konular',
        aciklama: 'Takımımız hakkında genel sohbet',
        ikon: Icons.chat,
        renk: const Color(0xFF4CAF50),
        sira: 1,
        olusturmaTarihi: DateTime.now(),
      ),
      ForumKategori(
        id: 'maclar',
        ad: 'Maç Konuları',
        aciklama: 'Oynanan ve oynanacak maçlar hakkında',
        ikon: Icons.sports_soccer,
        renk: const Color(0xFF2196F3),
        sira: 2,
        olusturmaTarihi: DateTime.now(),
      ),
      ForumKategori(
        id: 'transferler',
        ad: 'Transfer & Kadro',
        aciklama: 'Transfer haberleri ve kadro değişiklikleri',
        ikon: Icons.swap_horiz,
        renk: const Color(0xFFFF9800),
        sira: 3,
        olusturmaTarihi: DateTime.now(),
      ),
      ForumKategori(
        id: 'tarihce',
        ad: 'Tarihçe & Anılar',
        aciklama: 'Kulübümüzün tarihçesi ve güzel anılar',
        ikon: Icons.history_edu,
        renk: const Color(0xFF9C27B0),
        sira: 4,
        olusturmaTarihi: DateTime.now(),
      ),
      ForumKategori(
        id: 'diger',
        ad: 'Diğer',
        aciklama: 'Futbol dışı konular',
        ikon: Icons.more_horiz,
        renk: const Color(0xFF607D8B),
        sira: 5,
        olusturmaTarihi: DateTime.now(),
      ),
    ];
  }
}