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

class _AdminPanelScreenState extends State<AdminPanelScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          // İstatistik kartları
          _buildStatsSection(),

          // Tab bar
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Genel'),
                Tab(icon: Icon(Icons.people), text: 'Kullanıcılar'),
                Tab(icon: Icon(Icons.article), text: 'Haberler'),
                Tab(icon: Icon(Icons.sports_soccer), text: 'Oyuncular'),
                Tab(icon: Icon(Icons.history), text: 'Loglar'),
              ],
            ),
          ),

          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
                _buildNewsTab(),
                _buildPlayersTab(),
                _buildLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Kullanıcı', _stats['totalUsers'] ?? 0, Icons.people, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Haber', _stats['totalNews'] ?? 0, Icons.article, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Oyuncu', _stats['totalPlayers'] ?? 0, Icons.sports, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Maç', _stats['totalMatches'] ?? 0, Icons.event, Colors.red)),
        ],
      ),
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

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hızlı eylemler
          _buildQuickActionsCard(),
          const SizedBox(height: 16),

          // Son aktiviteler
          _buildRecentActivitiesCard(),
          const SizedBox(height: 16),

          // Sistem durumu
          _buildSystemStatusCard(),
        ],
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
                _buildQuickActionButton('Haber Ekle', Icons.add_box, () => _showAddNewsDialog()),
                _buildQuickActionButton('Oyuncu Ekle', Icons.person_add, () => _showAddPlayerDialog()),
                _buildQuickActionButton('Maç Ekle', Icons.add_circle, () => _showAddMatchDialog()),
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
                        _getActionIcon(data['action']),
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

  Widget _buildSystemStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sistem Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusItem('Firestore Bağlantısı', true),
            _buildStatusItem('Authentication', true),
            _buildStatusItem('Admin Servisleri', true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.error,
            color: isOnline ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(title),
          const Spacer(),
          Text(
            isOnline ? 'Aktif' : 'Çevrimdışı',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['photoURL'] != null
                      ? NetworkImage(data['photoURL'])
                      : null,
                  child: data['photoURL'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(data['displayName'] ?? 'İsim yok'),
                subtitle: Text(data['email'] ?? 'E-posta yok'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data['isAdmin'] == true)
                      const Icon(Icons.admin_panel_settings, color: Colors.orange),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        if (data['isAdmin'] != true)
                          PopupMenuItem(
                            value: 'make_admin',
                            child: const Row(
                              children: [
                                Icon(Icons.admin_panel_settings),
                                SizedBox(width: 8),
                                Text('Admin Yap'),
                              ],
                            ),
                          ),
                        if (data['isAdmin'] == true)
                          PopupMenuItem(
                            value: 'remove_admin',
                            child: const Row(
                              children: [
                                Icon(Icons.remove_moderator),
                                SizedBox(width: 8),
                                Text('Admin Kaldır'),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) => _handleUserAction(value.toString(), data),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('haberler')
          .orderBy('tarih', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['tarih'] as Timestamp?;

            return Card(
              child: ListTile(
                title: Text(data['baslik'] ?? 'Başlık yok'),
                subtitle: Text(
                  timestamp?.toDate().toString().split(' ')[0] ?? 'Tarih yok',
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleNewsAction(value.toString(), doc.id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Takım')
          .orderBy('formaNo')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['fotoUrl'] != null
                      ? NetworkImage(data['fotoUrl'])
                      : null,
                  child: data['fotoUrl'] == null
                      ? Text('${data['formaNo'] ?? '?'}')
                      : null,
                ),
                title: Text(data['isim'] ?? 'İsim yok'),
                subtitle: Text('${data['pozisyon'] ?? 'Pozisyon yok'} - Forma: ${data['formaNo'] ?? '?'}'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handlePlayerAction(value.toString(), doc.id, data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;

            return Card(
              child: ListTile(
                leading: Icon(_getActionIcon(data['action'])),
                title: Text(data['action'] ?? 'Bilinmeyen işlem'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin: ${data['adminEmail'] ?? 'Bilinmeyen'}'),
                    Text('Tarih: ${timestamp?.toDate().toString() ?? 'Tarih yok'}'),
                    if (data['details'] != null)
                      Text('Detay: ${data['details'].toString()}'),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
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

  void _handleUserAction(String action, Map<String, dynamic> userData) async {
    switch (action) {
      case 'make_admin':
        final success = await AdminService.makeUserAdmin(userData['email']);
        if (success) {
          await AdminService.logAdminActivity(
            action: 'USER_MADE_ADMIN',
            targetType: 'USER',
            targetId: userData['email'],
          );
          _showSuccessSnackBar('Kullanıcı admin yapıldı');
        } else {
          _showErrorSnackBar('Admin yapılamadı');
        }
        break;
      case 'remove_admin':
        final success = await AdminService.removeAdminRole(userData['email']);
        if (success) {
          await AdminService.logAdminActivity(
            action: 'USER_ADMIN_REMOVED',
            targetType: 'USER',
            targetId: userData['email'],
          );
          _showSuccessSnackBar('Admin yetkisi kaldırıldı');
        } else {
          _showErrorSnackBar('Admin yetkisi kaldırılamadı');
        }
        break;
    }
  }

  void _handleNewsAction(String action, String newsId, Map<String, dynamic> newsData) async {
    switch (action) {
      case 'delete':
        final confirm = await _showConfirmDialog('Bu haberi silmek istediğinizden emin misiniz?');
        if (confirm) {
          try {
            await FirebaseFirestore.instance.collection('haberler').doc(newsId).delete();
            await AdminService.logAdminActivity(
              action: 'NEWS_DELETED',
              targetType: 'NEWS',
              targetId: newsId,
            );
            _showSuccessSnackBar('Haber silindi');
          } catch (e) {
            _showErrorSnackBar('Haber silinemedi: $e');
          }
        }
        break;
    }
  }

  void _handlePlayerAction(String action, String playerId, Map<String, dynamic> playerData) async {
    switch (action) {
      case 'delete':
        final confirm = await _showConfirmDialog('Bu oyuncuyu silmek istediğinizden emin misiniz?');
        if (confirm) {
          try {
            await FirebaseFirestore.instance.collection('Takım').doc(playerId).delete();
            await AdminService.logAdminActivity(
              action: 'PLAYER_DELETED',
              targetType: 'PLAYER',
              targetId: playerId,
            );
            _showSuccessSnackBar('Oyuncu silindi');
          } catch (e) {
            _showErrorSnackBar('Oyuncu silinemedi: $e');
          }
        }
        break;
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Onay'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showAddNewsDialog() {
    // News ekleme dialog'u buraya gelecek
    _showErrorSnackBar('Haber ekleme özelliği yakında eklenecek');
  }

  void _showAddPlayerDialog() {
    // Player ekleme dialog'u buraya gelecek
    _showErrorSnackBar('Oyuncu ekleme özelliği yakında eklenecek');
  }

  void _showAddMatchDialog() {
    // Maç ekleme dialog'u buraya gelecek
    _showErrorSnackBar('Maç ekleme özelliği yakında eklenecek');
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