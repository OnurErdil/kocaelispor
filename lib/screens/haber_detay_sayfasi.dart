// lib/screens/haber_detay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/haber_model.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class HaberDetaySayfasi extends StatelessWidget {
  final Haber haber;

  const HaberDetaySayfasi({super.key, required this.haber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Haber Detayı",
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareNews(context),
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim (varsa)
            if (haber.resimUrl != null && haber.resimUrl!.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  haber.resimUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori ve önemli işareti
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Haber.getKategoriColor(haber.kategori).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Haber.getKategoriIcon(haber.kategori),
                              size: 18,
                              color: Haber.getKategoriColor(haber.kategori),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              haber.kategori,
                              style: TextStyle(
                                fontSize: 14,
                                color: Haber.getKategoriColor(haber.kategori),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (haber.onemli) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.priority_high, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'ÖNEMLİ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Başlık
                  Text(
                    haber.baslik,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarih ve yazar bilgileri
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          haber.formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (haber.yazar != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.person,
                            size: 18,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            haber.yazar!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // İçerik
                  Text(
                    haber.icerik,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Etiketler (varsa)
                  if (haber.etiketler.isNotEmpty) ...[
                    const Text(
                      'Etiketler',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: haber.etiketler.map((etiket) {
                        return Chip(
                          label: Text(etiket),
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Paylaş butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareNews(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Haberi Paylaş'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kocaelispor footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Kocaelispor 1966 - Resmi Haber',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareNews(BuildContext context) {
    HapticFeedback.lightImpact();

    final shareText = '''
🔥 ${haber.baslik}

📝 ${haber.icerik.length > 150 ? '${haber.icerik.substring(0, 150)}...' : haber.icerik}

📅 ${haber.formattedDate}
🏷️ ${haber.kategori}

⚽ Kocaelispor 1966 Taraftar Uygulaması
''';

    // Clipboard'a kopyala
    Clipboard.setData(ClipboardData(text: shareText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Haber panoya kopyalandı!'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}