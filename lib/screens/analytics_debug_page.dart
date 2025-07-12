// lib/screens/analytics_debug_page.dart
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class AnalyticsDebugPage extends StatefulWidget {
  const AnalyticsDebugPage({super.key});

  @override
  State<AnalyticsDebugPage> createState() => _AnalyticsDebugPageState();
}

class _AnalyticsDebugPageState extends State<AnalyticsDebugPage> {
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Analytics Debug",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test butonları
            Text(
              "Test Analytics Events",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Test butonları grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3,
              children: [
                _buildTestButton(
                  "Kadro Görüntüle",
                      () => _testEvent(() => AnalyticsService.logViewTeam()),
                ),
                _buildTestButton(
                  "Takvim Görüntüle",
                      () => _testEvent(() => AnalyticsService.logViewFixture()),
                ),
                _buildTestButton(
                  "Puan Durumu",
                      () => _testEvent(() => AnalyticsService.logViewLeagueTable()),
                ),
                _buildTestButton(
                  "Oyuncu Detay",
                      () => _testEvent(() => AnalyticsService.logViewPlayer("Test Oyuncu", 10)),
                ),
                _buildTestButton(
                  "Arama Yap",
                      () => _testEvent(() => AnalyticsService.logSearch("test", "players")),
                ),
                _buildTestButton(
                  "Hata Kaydet",
                      () => _testEvent(() => AnalyticsService.logError("test_error", "Test hata mesajı")),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Log başlığı
            Text(
              "Event Logs",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Temizle butonu
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _logs.clear()),
                icon: const Icon(Icons.clear_all),
                label: const Text("Temizle"),
              ),
            ),

            // Log listesi
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _logs.isEmpty
                    ? const Center(
                  child: Text(
                    "Henüz event yok.\nTest butonlarına tıklayın!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Firebase Console linki
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Firebase Console",
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Analytics verilerini gerçek zamanlı görmek için Firebase Console > Analytics bölümüne gidin.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
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

  Widget _buildTestButton(String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _testEvent(Function() eventFunction) {
    try {
      eventFunction();
      final timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        _logs.insert(0, "[$timestamp] Event gönderildi ✅");
      });
    } catch (e) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      setState(() {
        _logs.insert(0, "[$timestamp] Hata: $e ❌");
      });
    }
  }
}