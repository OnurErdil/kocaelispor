// lib/screens/forum_kategori_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../models/forum_models.dart';
import '../services/forum_service.dart';
import 'forum_konu_sayfasi.dart';
import 'konu_olustur_sayfasi.dart';

class ForumKategoriSayfasi extends StatefulWidget {
  final ForumKategori kategori;

  const ForumKategoriSayfasi({super.key, required this.kategori});

  @override
  State<ForumKategoriSayfasi> createState() => _ForumKategoriSayfasiState();
}

class _ForumKategoriSayfasiState extends State<ForumKategoriSayfasi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.kategori.ad,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _yeniKonuOlustur(),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Konu'),
      ),
      body: Column(
        children: [
          // Kategori başlığı ve bilgileri
          _buildKategoriBilgi(),

          // Konular listesi
          Expanded(
            child: StreamBuilder<List<ForumKonu>>(
              stream: ForumService.getKonular(widget.kategori.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorWidget('Konular yüklenirken hata oluştu');
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyWidget();
                }

                final konular = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: konular.length,
                    itemBuilder: (context, index) {
                      final konu = konular[index];
                      return _buildKonuCard(konu);
                    },
                  ),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.kategori.renk,
            widget.kategori.renk.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.kategori.ikon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kategori.ad,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.kategori.aciklama,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatChip(
                      Icons.topic,
                      '${widget.kategori.konuSayisi} konu',
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.message,
                      '${widget.kategori.mesajSayisi} mesaj',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKonuCard(ForumKonu konu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _konuyaGit(konu),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Konu başlığı ve etiketler
                Row(
                  children: [
                    // Sabitlenmis ikonu
                    if (konu.sabitlenmis)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                      ),

                    // Kilitli ikonu
                    if (konu.kilitli)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.red[600],
                        ),
                      ),

                    // Başlık
                    Expanded(
                      child: Text(
                        konu.baslik,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: konu.sabitlenmis ? FontWeight.bold : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Etiket
                    if (konu.etiket != null && konu.etiket!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: konu.etiketRengi.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: konu.etiketRengi.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          konu.etiketMetni,
                          style: TextStyle(
                            fontSize: 10,
                            color: konu.etiketRengi,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                // Açıklama (varsa)
                if (konu.aciklama != null && konu.aciklama!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    konu.aciklama!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Alt bilgiler
                Row(
                  children: [
                    // Oluşturan kişi
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primaryGreen,
                      backgroundImage: konu.olusturanFoto != null
                          ? NetworkImage(konu.olusturanFoto!)
                          : null,
                      child: konu.olusturanFoto == null
                          ? Text(
                        konu.olusturanAd[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            konu.olusturanAd,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            _formatTarih(konu.olusturmaTarihi),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // İstatistikler
                    _buildKonuStatistik(
                      Icons.message_outlined,
                      konu.mesajSayisi.toString(),
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildKonuStatistik(
                      Icons.visibility_outlined,
                      konu.goruntulemeSayisi.toString(),
                      Colors.green,
                    ),

                    // Son mesaj bilgisi
                    if (konu.sonMesajTarihi != null) ...[
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Son mesaj:',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(
                            _formatTarih(konu.sonMesajTarihi!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKonuStatistik(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_outlined,
            size: 64,
            color: widget.kategori.renk.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz konu yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk konuyu sen aç!',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _yeniKonuOlustur(),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.kategori.renk,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('İlk Konuyu Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
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
    );
  }

  void _yeniKonuOlustur() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konu oluşturmak için giriş yapmalısınız'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KonuOlusturSayfasi(kategori: widget.kategori),
      ),
    );
  }

  void _konuyaGit(ForumKonu konu) async {
    // Görüntüleme sayısını artır
    await ForumService.konuGoruntulemeSayisiniArtir(konu.id);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForumKonuSayfasi(konu: konu),
        ),
      );
    }
  }

  String _formatTarih(DateTime tarih) {
    final now = DateTime.now();
    final difference = now.difference(tarih);

    if (difference.inDays > 7) {
      return '${tarih.day}/${tarih.month}/${tarih.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }
}