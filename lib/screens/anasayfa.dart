import 'package:flutter/material.dart';
import 'kadro_sayfasi.dart';

class Anasayfa extends StatelessWidget {
  const Anasayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon ekleyerek daha görsel bir görünüm
            Icon(
              Icons.people,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),

            // Başlık metni
            Text(
              'Hoş Geldiniz!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),

            // Açıklama metni
            Text(
              'Kadro yönetimi için aşağıdaki butona tıklayın',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Ana buton
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Kadroya Git'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00913C), // Yeşil
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KadroSayfasi()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}