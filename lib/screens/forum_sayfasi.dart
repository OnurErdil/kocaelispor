// lib/screens/forum_sayfasi.dart - Çalışan Final Versiyon
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../models/forum_models.dart';
import '../services/forum_service.dart';
import 'konu_olustur_sayfasi.dart';
import 'forum_kategori_sayfasi.dart';

class ForumSayfasi extends StatefulWidget {
  const ForumSayfasi({super.key});

  @override
  State<ForumSayfasi> createState() => _ForumSayfasiState();
}

class _ForumSayfasiState extends State<ForumSayfasi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Forum",
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('forum_kategorileri')
            .orderBy('sira')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                  SizedBox(height: 16),
                  Text('Forum kategorileri yükleniyor...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Forum yüklenirken hata oluştu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hata: ${snapshot.error}',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 80,
                    color: AppTheme.primaryGreen.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Henüz kategori yok',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Forum kategorileri yakında eklenecek',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // ✅ BAŞARILI DURUM - KATEGORİLER GÖSTER
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildCategoryCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> data, String id) {
    final ad = _safeStringValue(data['ad'], 'Kategori');
    final aciklama = _safeStringValue(data['aciklama'], '');
    final ikonAdi = _safeStringValue(data['ikon'], 'chat');
    final renkDegeri = _safeIntValue(data['renk'], 0xFF4CAF50);
    final konuSayisi = _safeIntValue(data['konuSayisi'], 0);
    final mesajSayisi = _safeIntValue(data['mesajSayisi'], 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _goToCategory(data, id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(renkDegeri).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(ikonAdi),
                    color: Color(renkDegeri),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aciklama,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatItem(
                            Icons.topic_outlined,
                            '$konuSayisi Konu',
                            Color(renkDegeri),
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            Icons.message_outlined,
                            '$mesajSayisi Mesaj',
                            Colors.grey[600]!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'chat':
        return Icons.chat;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'history_edu':
        return Icons.history_edu;
      default:
        return Icons.forum;
    }
  }

  void _goToCategory(Map<String, dynamic> data, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KategoriDetaySayfasi(
          kategoriAd: data['ad'] ?? 'Kategori',
          kategoriId: id,
          kategoriRenk: Color(_safeIntValue(data['renk'], 0xFF4CAF50)),
          kategoriIkon: _getIconData(_safeStringValue(data['ikon'], 'chat')),
        ),
      ),
    );
  }

  // Güvenli değer alma fonksiyonları
  String _safeStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  int _safeIntValue(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }
}

// ============================================
// KATEGORİ DETAY SAYFASI
// ============================================
class KategoriDetaySayfasi extends StatelessWidget {
  final String kategoriAd;
  final String kategoriId;
  final Color kategoriRenk;
  final IconData kategoriIkon;

  const KategoriDetaySayfasi({
    super.key,
    required this.kategoriAd,
    required this.kategoriId,
    required this.kategoriRenk,
    required this.kategoriIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kategoriAd),
        backgroundColor: kategoriRenk,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _yeniKonuOlustur(context),
        backgroundColor: kategoriRenk,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Konu'),
      ),
      body: Column(
        children: [
          _buildKategoriBilgi(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_konulari')
                  .where('kategoriId', isEqualTo: kategoriId)
                  .orderBy('olusturmaTarihi', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Hata: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Geri Dön'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyWidget(context);
                }

                final konular = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: konular.length,
                  itemBuilder: (context, index) {
                    final data = konular[index].data() as Map<String, dynamic>;
                    return _buildKonuCard(context, data, konular[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriBilgi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kategoriRenk.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: kategoriRenk.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            kategoriIkon,
            color: kategoriRenk,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kategoriAd,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kategoriRenk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Konuları görüntüleyin ve yeni konu açın',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700], // ✅ Beyaz yerine koyu gri
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_outlined,
            size: 80,
            color: kategoriRenk.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz konu yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk konuyu sen aç!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _yeniKonuOlustur(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kategoriRenk,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('İlk Konuyu Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildKonuCard(BuildContext context, Map<String, dynamic> data, String konuId) {
    final baslik = data['baslik'] ?? 'Başlıksız Konu';
    final olusturanAd = data['olusturanAd'] ?? 'Anonim';
    final mesajSayisi = data['mesajSayisi'] ?? 0;
    final goruntulemeSayisi = data['goruntulemeSayisi'] ?? 0;
    final sabitlenmis = data['sabitlenmis'] ?? false;
    final etiket = data['etiket'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _konuyaGit(context, data, konuId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve etiketler
                Row(
                  children: [
                    if (sabitlenmis) ...[
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: kategoriRenk,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        baslik,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (etiket != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getEtiketColor(etiket),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getEtiketText(etiket),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Alt bilgiler
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      olusturanAd,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.message,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$mesajSayisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.visibility,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$goruntulemeSayisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getEtiketColor(String etiket) {
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

  String _getEtiketText(String etiket) {
    switch (etiket) {
      case 'hot':
        return 'Popüler';
      case 'new':
        return 'Yeni';
      case 'important':
        return 'Önemli';
      default:
        return 'Genel';
    }
  }

  void _yeniKonuOlustur(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KonuOlusturSayfasi(
          kategori: ForumKategori(
            id: kategoriId,
            ad: kategoriAd,
            aciklama: '',
            ikon: kategoriIkon,
            renk: kategoriRenk,
            sira: 0,
            olusturmaTarihi: DateTime.now(),
          ),
        ),
      ),
    );
  }

  void _konuyaGit(BuildContext context, Map<String, dynamic> data, String konuId) {
    // Önce görüntüleme sayısını artır
    FirebaseFirestore.instance
        .collection('forum_konulari')
        .doc(konuId)
        .update({'goruntulemeSayisi': FieldValue.increment(1)});

    // Konu detay sayfasına git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumKonuSayfasi(
          konu: ForumKonu(
            id: konuId,
            baslik: data['baslik'] ?? 'Başlıksız Konu',
            aciklama: data['aciklama'] ?? '',
            kategoriId: kategoriId,
            olusturanId: data['olusturanId'] ?? '',
            olusturanAd: data['olusturanAd'] ?? 'Anonim',
            olusturmaTarihi: DateTime.now(),
            mesajSayisi: data['mesajSayisi'] ?? 0,
            goruntulemeSayisi: data['goruntulemeSayisi'] ?? 0,
            sonMesajTarihi: DateTime.now(),
            etiket: data['etiket'],
            sabitlenmis: data['sabitlenmis'] ?? false,
          ),
        ),
      ),
    );
  }
}