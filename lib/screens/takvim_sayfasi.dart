import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kocaelispor_1966_mobil/screens/puan_durumu_sayfasi.dart';
import '../widgets/custom_app_bar.dart'; // ✅ Import ekleyin

class TakvimSayfasi extends StatelessWidget {
  const TakvimSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Fikstür & Takvim",
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddMatchDialog(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fikstür & Sonuçlar",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 🔴 Son Oynanan Maç Kartı
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fixture')
                  .where('tarih',
                  isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
                  .orderBy('tarih', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                // ✅ Hata durumu düzgün yönetimi
                if (snapshot.hasError) {
                  return _buildErrorCard(
                    "Son maç yüklenemiyor",
                    snapshot.error.toString(),
                    Icons.sports_soccer,
                  );
                }

                // ✅ Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard();
                }

                // ✅ Null safety
                if (!snapshot.hasData || snapshot.data == null) {
                  return _buildErrorCard(
                    "Veri yüklenemedi",
                    "Bağlantı sorunu olabilir",
                    Icons.cloud_off,
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return _buildEmptyCard("Henüz oynanmış maç yok", Icons.schedule);
                }

                // ✅ Güvenli veri çekme
                try {
                  final doc = snapshot.data!.docs.first;
                  final match = doc.data() as Map<String, dynamic>?;

                  if (match == null) {
                    return _buildErrorCard(
                      "Maç verisi okunamadı",
                      "Veri formatı hatalı",
                      Icons.error_outline,
                    );
                  }

                  return _buildMatchCard(match);
                } catch (e) {
                  return _buildErrorCard(
                    "Maç verisi işlenemiyor",
                    e.toString(),
                    Icons.bug_report,
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // 🟢 Yaklaşan Maç Kartı
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fixture')
                  .where('tarih', isGreaterThan: Timestamp.now())
                  .orderBy('tarih')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                // ✅ Hata durumu düzgün yönetimi
                if (snapshot.hasError) {
                  return _buildErrorCard(
                    "Yaklaşan maç yüklenemiyor",
                    snapshot.error.toString(),
                    Icons.event,
                  );
                }

                // ✅ Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard();
                }

                // ✅ Null safety
                if (!snapshot.hasData || snapshot.data == null) {
                  return _buildErrorCard(
                    "Veri yüklenemedi",
                    "Bağlantı sorunu olabilir",
                    Icons.cloud_off,
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return _buildEmptyCard("Yaklaşan maç yok", Icons.event_busy);
                }

                // ✅ Güvenli veri çekme
                try {
                  final doc = snapshot.data!.docs.first;
                  final match = doc.data() as Map<String, dynamic>?;

                  if (match == null) {
                    return _buildErrorCard(
                      "Maç verisi okunamadı",
                      "Veri formatı hatalı",
                      Icons.error_outline,
                    );
                  }

                  return _buildMatchCard(match);
                } catch (e) {
                  return _buildErrorCard(
                    "Maç verisi işlenemiyor",
                    e.toString(),
                    Icons.bug_report,
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Tüm fikstür sayfasına yönlendir
                },
                child: const Text("Bütün Fikstür & Sonuçları Görüntüle"),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PuanDurumuSayfasi()),
                  );
                },
                child: const Text("Puan Durumu"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Hata kartı widget'ı
  Widget _buildErrorCard(String title, String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.red.shade600),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ Loading kartı widget'ı
  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            "Maç bilgileri yükleniyor...",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ✅ Empty state kartı widget'ı
  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    // ✅ Null safety ile güvenli değer çekme
    final tarihTimestamp = match['tarih'] as Timestamp?;
    if (tarihTimestamp == null) {
      return _buildErrorCard(
        "Tarih bilgisi eksik",
        "Maç tarihi bulunamadı",
        Icons.date_range,
      );
    }

    final dateTime = tarihTimestamp.toDate();
    final formattedDate = "${dateTime.day}.${dateTime.month}.${dateTime.year}";

    // ✅ Güvenli değer atamaları
    final durum = match['durum'] as String? ?? 'Bilinmiyor';
    final skor = match['skor'] as String? ?? '-';
    final saat = match['saat'] as String? ?? '';
    final lig = match['lig'] as String? ?? 'Lig Yok';
    final rakip = match['rakip'] as String? ?? 'Rakip Yok';
    final evSahibi = match['evSahibi'] as String? ?? 'Ev Sahibi';
    final evLogo = match['evSahibiLogo'] as String? ?? '';
    final rakipLogo = match['rakipLogo'] as String? ?? '';

    String gosterim;
    if (durum == "Yaklaşan") {
      gosterim = "${dateTime.day}.${dateTime.month}";
    } else {
      gosterim = skor;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/images/stadium_bg.png"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black54,
            BlendMode.darken,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Üst Lig
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lig,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),

          // Skor kutusu üstü tarih sadece oynanmış maç için
          if (durum != "Yaklaşan")
            Text(
              formattedDate,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),

          const SizedBox(height: 8),

          // Takımlar & Skor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ev Sahibi
              Column(
                children: [
                  _buildTeamLogo(evLogo, evSahibi),
                  const SizedBox(height: 6),
                  Text(evSahibi,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              // Skor Kutusu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  gosterim,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              // Rakip
              Column(
                children: [
                  _buildTeamLogo(rakipLogo, rakip),
                  const SizedBox(height: 6),
                  Text(rakip, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Durum veya Saat
          durum == "Yaklaşan"
              ? Text(saat,
              style: const TextStyle(fontSize: 16, color: Colors.white))
              : Text(durum,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ✅ Takım logosu güvenli widget'ı
  Widget _buildTeamLogo(String logoUrl, String teamName) {
    // Eğer logo URL'i boş ise placeholder göster
    if (logoUrl.isEmpty) {
      return Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.sports_soccer,
          size: 30,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      logoUrl,
      height: 50,
      width: 50,
      fit: BoxFit.contain,
      // ✅ Hata durumunda placeholder
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                size: 20,
                color: Colors.grey,
              ),
              Text(
                teamName.length > 3 ? teamName.substring(0, 3) : teamName,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      // ✅ Yükleme durumunda loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  void _showAddMatchDialog(BuildContext context) {
    final TextEditingController jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Yeni Maç JSON'u"),
          content: TextField(
            controller: jsonController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: '''
{
  "lig": "Super Lig",
  "tarih": "2025-07-20",
  "saat": "20:00",
  "evSahibi": "Kocaelispor",
  "rakip": "Beşiktaş",
  "evSahibiLogo": "https://example.com/kocaeli.png",
  "rakipLogo": "https://example.com/besiktas.png",
  "skor": "0-0",
  "durum": "Yaklaşan"
}
''',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // ✅ JSON validation
                if (jsonController.text.trim().isEmpty) {
                  _showErrorSnackBar(context, "JSON boş olamaz");
                  return;
                }

                try {
                  final parsed = jsonDecode(jsonController.text);

                  if (parsed is List) {
                    for (var match in parsed) {
                      await _addMatchToFirestore(match, context);
                    }
                  } else if (parsed is Map) {
                    await _addMatchToFirestore(parsed, context);
                  } else {
                    throw Exception("Geçersiz JSON formatı");
                  }

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    _showSuccessSnackBar(context, "Fixture eklendi ✅");
                  }
                } catch (e) {
                  print("JSON Hata: $e");
                  _showErrorSnackBar(context, "JSON format hatası: $e");
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Firestore ekleme işlemi ayrı metod
  Future<void> _addMatchToFirestore(dynamic match, BuildContext context) async {
    try {
      final map = match as Map<String, dynamic>;

      // ✅ Tarih validation
      if (map['tarih'] == null) {
        throw Exception("Tarih alanı zorunlu");
      }

      final DateTime tarih = DateTime.parse(map['tarih']);
      map['tarih'] = Timestamp.fromDate(tarih);

      await FirebaseFirestore.instance.collection('fixture').add(map);
    } catch (e) {
      print("Firestore Hata: $e");
      throw Exception("Veritabanı hatası: $e");
    }
  }

  // ✅ Hata mesajı gösterme
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ Başarı mesajı gösterme
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}