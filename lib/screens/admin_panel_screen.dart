// lib/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';

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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // İstatistik kartları
            _buildStatsSection(),
            const SizedBox(height: 16),

            // Hızlı eylemler
            _buildQuickActionsCard(),
            const SizedBox(height: 16),

            // Son aktiviteler
            _buildRecentActivitiesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Kullanıcı', _stats['totalUsers'] ?? 0, Icons.people, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Haber', _stats['totalNews'] ?? 0, Icons.article, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Oyuncu', _stats['totalPlayers'] ?? 0, Icons.sports, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Maç', _stats['totalMatches'] ?? 0, Icons.event, Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Eylemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildQuickActionButton('Haber Ekle', Icons.add_box, () => _showComingSoonDialog('Haber Ekleme')),
                _buildQuickActionButton('Oyuncu Ekle', Icons.person_add, () => _showComingSoonDialog('Oyuncu Ekleme')),
                _buildQuickActionButton('Maç Ekle', Icons.add_circle, () => _showComingSoonDialog('Maç Ekleme')),
                _buildQuickActionButton('Admin Yap', Icons.admin_panel_settings, () => _showMakeAdminDialog()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    final dateStr = timestamp?.toDate().toString().split(' ')[0] ?? 'Tarih yok';

                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 16),
                      title: Text(
                        data['action'] ?? 'Bilinmeyen işlem',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${data['adminEmail'] ?? 'Bilinmeyen'} - $dateStr',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: Colors.grey,
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
            child: const Text('Admin Yap'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature'),
        content: Text('$feature özelliği yakında eklenecek!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}