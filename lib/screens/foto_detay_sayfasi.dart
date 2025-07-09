// lib/screens/foto_detay_sayfasi.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class FotoDetaySayfasi extends StatelessWidget {
  final String fotoUrl;
  final String oyuncuAdi;
  final String pozisyon;
  final int formaNo;

  const FotoDetaySayfasi({
    super.key,
    required this.fotoUrl,
    required this.oyuncuAdi,
    required this.pozisyon,
    required this.formaNo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: oyuncuAdi,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Üst bilgi kartı
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00913C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Forma numarası
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$formaNo',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00913C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Oyuncu bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oyuncuAdi,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pozisyon,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Kocaelispor ikonu
                const Icon(
                  Icons.sports_soccer,
                  size: 30,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          // Ana fotoğraf
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Hero(
                  tag: 'oyuncu_foto_$formaNo', // Animasyon için
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      fotoUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      // Hata durumunda placeholder
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                oyuncuAdi,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Fotoğraf yüklenemedi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      // Yükleme durumunda
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00913C),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Alt bilgi kartı
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Forma', '$formaNo'),
                _buildInfoItem('Pozisyon', pozisyon),
                _buildInfoItem('Takım', 'Kocaelispor'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bilgi öğesi widget'ı
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}