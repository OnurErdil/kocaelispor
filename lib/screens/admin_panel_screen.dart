// lib/screens/admin_panel_screen.dart - DÜZELTİLMİŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import 'admin_notification_panel.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await AdminService.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('İstatistikler yüklenemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Admin Paneli",
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView( // ✅ Overflow sorunu çözümü
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // İstatistik kartları
              _buildStatsSection(),
              const SizedBox(height: 16),

              // Hızlı eylemler - GELİŞTİRİLDİ
              _buildQuickActionsCard(),
              const SizedBox(height: 16),

              // Admin kontrolleri - YENİ
              _buildAdminControlsCard(),
              const SizedBox(height: 16),

              // Son aktiviteler
              _buildRecentActivitiesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Kullanıcı',
            value: _stats['totalUsers'] ?? 0,
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Haber',
            value: _stats['totalNews'] ?? 0,
            icon: Icons.article,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Oyuncu',
            value: _stats['totalPlayers'] ?? 0,
            icon: Icons.sports,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Maç',
            value: _stats['totalMatches'] ?? 0,
            icon: Icons.sports_soccer,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  // Hızlı eylemler - GELİŞTİRİLDİ
  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Eylemler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // İlk satır
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.notifications_active,
                    label: 'Push Bildirim',
                    onPressed: _openNotificationPanel,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.person_add,
                    label: 'Admin Yap',
                    onPressed: _showMakeAdminDialog,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // İkinci satır
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.article_outlined,
                    label: 'Haber Ekle',
                    onPressed: _showAddNewsDialog,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.sports_soccer,
                    label: 'Maç Ekle',
                    onPressed: _showAddMatchDialog,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Admin kontrolleri - YENİ KART
  Widget _buildAdminControlsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sistem Kontrolleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // İlk satır
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.sports,
                    label: 'Oyuncu Ekle',
                    onPressed: _showAddPlayerDialog,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.leaderboard,
                    label: 'Puan Durumu',
                    onPressed: _showStandingsDialog,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // İkinci satır
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.backup,
                    label: 'Yedek Al',
                    onPressed: _showBackupDialog,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.analytics,
                    label: 'İstatistikler',
                    onPressed: _showAnalyticsDialog,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_logs')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Text('Henüz aktivite yok');
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateStr = timestamp != null
                        ? '${timestamp.toDate().day}/${timestamp.toDate().month} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                        : 'Bilinmeyen';

                    return ListTile(
                      leading: Icon(_getActionIcon(data['action'])),
                      title: Text(
                        data['action'] ?? 'Bilinmeyen işlem',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${data['adminEmail'] ?? 'Bilinmeyen'} - $dateStr',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String? action) {
    switch (action) {
      case 'ADMIN_PANEL_ACCESS':
        return Icons.dashboard;
      case 'USER_MADE_ADMIN':
        return Icons.admin_panel_settings;
      case 'USER_ADMIN_REMOVED':
        return Icons.remove_moderator;
      case 'NEWS_CREATED':
        return Icons.article;
      case 'PLAYER_CREATED':
        return Icons.person_add;
      default:
        return Icons.history;
    }
  }

  // Dialog fonksiyonları
  void _openNotificationPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminNotificationPanel(),
      ),
    );
  }

  void _showMakeAdminDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Admin Yap'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'E-posta Adresi',
            hintText: 'ornek@email.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(context);

              final success = await AdminService.makeUserAdmin(email);
              if (success) {
                await AdminService.logAdminActivity(
                  action: 'USER_MADE_ADMIN',
                  targetType: 'USER',
                  details: {'email': email},
                );
                _showSuccessSnackBar('Kullanıcı admin yapıldı');
              } else {
                _showErrorSnackBar('Kullanıcı bulunamadı veya admin yapılamadı');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Admin Yap'),
          ),
        ],
      ),
    );
  }

  void _showAddNewsDialog() => _showFeatureDialog('Haber Ekleme', 'Haber ekleme özelliği aktif! Haberler sayfasından haber ekleyebilirsiniz.');
  void _showAddPlayerDialog() => _showFeatureDialog('Oyuncu Ekleme', 'Oyuncu ekleme özelliği aktif! Kadro sayfasından oyuncu ekleyebilirsiniz.');
  void _showAddMatchDialog() => _showFeatureDialog('Maç Ekleme', 'Maç ekleme özelliği aktif! Takvim sayfasından maç ekleyebilirsiniz.');
  void _showStandingsDialog() => _showFeatureDialog('Puan Durumu', 'Puan durumu yönetimi aktif! Puan durumu sayfasından düzenleyebilirsiniz.');
  void _showBackupDialog() => _showComingSoonDialog('Yedekleme');
  void _showAnalyticsDialog() => _showComingSoonDialog('Analitik Rapor');

  void _showFeatureDialog(String feature, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(feature),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            const SizedBox(width: 8),
            Text(feature),
          ],
        ),
        content: Text('$feature özelliği yakında eklenecek!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// İstatistik kartı widget'ı
class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Aksiyon butonu widget'ı
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}