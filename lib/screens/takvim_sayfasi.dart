import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kocaelispor_1966_mobil/screens/puan_durumu_sayfasi.dart';

class TakvimSayfasi extends StatelessWidget {
  const TakvimSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Takım")),
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                if (snapshot.hasError) {
                  return const Center(child: Text("Hata oluştu!"));
                }
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Oynanmış maç yok!"));
                }

                final match =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return _buildMatchCard(match);
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
                if (snapshot.hasError) {
                  return const Center(child: Text("Hata oluştu!"));
                }
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Maç yok!"));
                }

                final match =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return _buildMatchCard(match);
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Tüm fikstür sayfasına yönlendir
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

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final Timestamp tarihTimestamp = match['tarih'] as Timestamp;
    final dateTime = tarihTimestamp.toDate();
    final formattedDate = "${dateTime.day}.${dateTime.month}.${dateTime.year}";

    String gosterim;
    if (match['durum'] == "Yaklaşan") {
      gosterim = "${dateTime.day}.${dateTime.month}";
    } else {
      gosterim = match['skor'] ?? '-';
    }

    final saat = match['saat'] ?? '';
    final lig = match['lig'] ?? 'Lig Yok';
    final rakip = match['rakip'] ?? 'Rakip Yok';
    final evSahibi = match['evSahibi'] ?? 'Ev Sahibi';
    final evLogo = match['evSahibiLogo'] ?? '';
    final rakipLogo = match['rakipLogo'] ?? '';

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
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16)),
              // Sağ üstte tarih yok!
            ],
          ),
          const SizedBox(height: 8),

          // Skor kutusu üstü tarih sadece oynanmış maç için
          if (match['durum'] != "Yaklaşan")
            Text(
              formattedDate,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14),
            ),

          const SizedBox(height: 8),

          // Takımlar & Skor
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ev Sahibi
              Column(
                children: [
                  Image.network(evLogo, height: 50),
                  const SizedBox(height: 6),
                  Text(evSahibi,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              // Skor Kutusu
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 18),
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
                  Image.network(rakipLogo, height: 50),
                  const SizedBox(height: 6),
                  Text(rakip,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Durum veya Saat
          match['durum'] == "Yaklaşan"
              ? Text(saat,
              style: const TextStyle(
                  fontSize: 16, color: Colors.white))
              : Text(match['durum'] ?? '',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
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
                try {
                  final parsed = jsonDecode(jsonController.text);

                  if (parsed is List) {
                    for (var match in parsed) {
                      final map = match as Map<String, dynamic>;
                      final DateTime tarih = DateTime.parse(map['tarih']);
                      map['tarih'] = Timestamp.fromDate(tarih);

                      await FirebaseFirestore.instance
                          .collection('fixture')
                          .add(map);
                    }
                  } else if (parsed is Map) {
                    final map = parsed as Map<String, dynamic>;
                    final DateTime tarih = DateTime.parse(map['tarih']);
                    map['tarih'] = Timestamp.fromDate(tarih);

                    await FirebaseFirestore.instance
                        .collection('fixture')
                        .add(map);
                  } else {
                    throw Exception("Geçersiz JSON formatı");
                  }

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fixture eklendi ✅")),
                  );
                } catch (e) {
                  print("Hata: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: $e")),
                  );
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }
}
