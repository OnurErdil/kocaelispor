// lib/screens/istatistikler_sayfasi.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../services/statistics_service.dart';
import '../theme/app_theme.dart';

class IstatistiklerSayfasi extends StatefulWidget {
  const IstatistiklerSayfasi({super.key});

  @override
  State<IstatistiklerSayfasi> createState() => _IstatistiklerSayfasiState();
}

class _IstatistiklerSayfasiState extends State<IstatistiklerSayfasi> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    final stats = await StatisticsService.getAllStatistics();

    if (mounted) {
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "İstatistikler",
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text('İstatistikler yükleniyor...'),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Taraftar İstatistikleri',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Ana istatistikler
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    title: 'Toplam Taraftar',
                    value: StatisticsService.formatNumber(_statistics?['totalUsers'] ?? 0),
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    icon: Icons.forum,
                    title: 'Forum Mesajları',
                    value: StatisticsService.formatNumber(_statistics?['totalMessages'] ?? 0),
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    icon: Icons.sports_soccer,
                    title: 'Takım Oyuncusu',
                    value: StatisticsService.formatNumber(_statistics?['totalPlayers'] ?? 0),
                    color: AppTheme.primaryGreen,
                  ),
                  _buildStatCard(
                    icon: Icons.today,
                    title: 'Bugünkü Mesajlar',
                    value: StatisticsService.formatNumber(_statistics?['todayMessages'] ?? 0),
                    color: Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // En aktif taraftar
              if (_statistics?['mostActiveUser'] != null) ...[
                const Text(
                  'En Aktif Taraftar',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActiveUserCard(),
                const SizedBox(height: 24),
              ],

              // Detaylı bilgiler
              _buildDetailedStats(),

              const SizedBox(height: 24),

              // Yenile butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadStatistics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('İstatistikleri Yenile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUserCard() {
    final activeUser = _statistics?['mostActiveUser'] as Map<String, dynamic>?;

    if (activeUser == null) {
      return const Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Henüz aktif taraftar yok'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star,
                size: 32,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeUser['name'] ?? 'Anonim Taraftar',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activeUser['messageCount'] ?? 0} mesaj gönderdi',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MVP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detaylı Bilgiler',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.people_outline,
              title: 'Kayıtlı Taraftarlar',
              value: '${_statistics?['totalUsers'] ?? 0} kişi',
            ),
            _buildDetailRow(
              icon: Icons.chat_bubble_outline,
              title: 'Toplam Mesajlar',
              value: '${_statistics?['totalMessages'] ?? 0} mesaj',
            ),
            _buildDetailRow(
              icon: Icons.sports_soccer_outlined,
              title: 'Kadrodaki Oyuncular',
              value: '${_statistics?['totalPlayers'] ?? 0} oyuncu',
            ),
            _buildDetailRow(
              icon: Icons.calendar_today,
              title: 'Bugün Gönderilen',
              value: '${_statistics?['todayMessages'] ?? 0} mesaj',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}