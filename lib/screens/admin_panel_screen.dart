// lib/screens/admin_panel_screen.dart - HATASIZ VERSİYON

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/admin_service.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // ✅ 6 sekme
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Yönetici Paneli",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sekme başlıkları
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: "İstatistik"),
                Tab(icon: Icon(Icons.people), text: "Kullanıcılar"),
                Tab(icon: Icon(Icons.article), text: "Haberler"),
                Tab(icon: Icon(Icons.sports), text: "Oyuncular"),
                Tab(icon: Icon(Icons.sports_soccer), text: "Maçlar"),
                Tab(icon: Icon(Icons.photo_library), text: "Takım Fotoları"),
              ],
            ),
          ),

          // Sekme içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(),
                _buildUsersTab(),
                _buildNewsTab(),
                _buildPlayersTab(),
                _buildMatchesTab(), // ✅ Bu fonksiyonu ekleyeceğiz
                _buildTeamPhotosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MAÇ SEKMESİ - EKSİK FONKSİYON
  Widget _buildMatchesTab() {
    return Column(
      children: [
        // Maç ekleme butonu
        Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addMatch,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Maç Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),

        // Maçlar listesi
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('maclar')
                .orderBy('tarih', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Henüz maç eklenmemiş',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final match = snapshot.data!.docs[index];
                  return _buildMatchCard(match);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ MAÇ KARTI
  Widget _buildMatchCard(DocumentSnapshot match) {
    final data = match.data() as Map<String, dynamic>;
    final homeTeam = data['ev_sahibi'] ?? 'Ev Sahibi';
    final awayTeam = data['deplasman'] ?? 'Deplasman';
    final date = data['tarih'] as Timestamp?;
    final stadium = data['stad'] ?? 'Belirtilmemiş';

    // Skor kontrolü
    final skor = data['skor'];
    bool isFinished = skor != null;
    String scoreText = 'VS';

    if (isFinished && skor is Map) {
      final homeScore = skor['ev_sahibi']?.toString() ?? '0';
      final awayScore = skor['deplasman']?.toString() ?? '0';
      scoreText = '$homeScore - $awayScore';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Takımlar ve skor
            Row(
              children: [
                Expanded(
                  child: Text(
                    homeTeam,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFinished ? Colors.green.shade700 : Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scoreText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    awayTeam,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Tarih ve stad
            Text(
              '${_formatDate(date?.toDate())} - $stadium',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 12),

            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _updateScore(match.id, data),
                  icon: const Icon(Icons.score, size: 16),
                  label: const Text('Skor'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _deleteMatch(match.id),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Sil', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MAÇ EKLEME FONKSİYONU
  Future<void> _addMatch() async {
    final result = await _showAddMatchDialog();
    if (result == null) return;

    try {
      await FirebaseFirestore.instance.collection('maclar').add({
        'ev_sahibi': result['homeTeam'],
        'deplasman': result['awayTeam'],
        'tarih': result['date'],
        'stad': result['stadium'],
        'skor': null,
        'olusturma_tarihi': FieldValue.serverTimestamp(),
        'olusturan': FirebaseAuth.instance.currentUser?.email ?? 'Admin',
      });

      _showSuccessSnackBar('Maç başarıyla eklendi');

    } catch (e) {
      _showErrorSnackBar('Maç eklenirken hata oluştu: $e');
    }
  }

  // ✅ MAÇ EKLEME DIALOG'U
  Future<Map<String, dynamic>?> _showAddMatchDialog() async {
    final TextEditingController homeTeamController = TextEditingController();
    final TextEditingController awayTeamController = TextEditingController();
    final TextEditingController stadiumController = TextEditingController();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 15, minute: 0);

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Maç Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: homeTeamController,
                  decoration: const InputDecoration(
                    labelText: 'Ev Sahibi Takım',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: awayTeamController,
                  decoration: const InputDecoration(
                    labelText: 'Deplasman Takım',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: stadiumController,
                  decoration: const InputDecoration(
                    labelText: 'Stad',
                    hintText: 'İsmet Paşa Stadı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tarih seçimi
                ListTile(
                  title: const Text('Maç Tarihi'),
                  subtitle: Text(_formatDate(selectedDate)),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),

                // Saat seçimi
                ListTile(
                  title: const Text('Maç Saati'),
                  subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final homeTeam = homeTeamController.text.trim();
                final awayTeam = awayTeamController.text.trim();
                final stadium = stadiumController.text.trim();

                if (homeTeam.isNotEmpty && awayTeam.isNotEmpty) {
                  final matchDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  Navigator.pop(context, {
                    'homeTeam': homeTeam,
                    'awayTeam': awayTeam,
                    'stadium': stadium.isNotEmpty ? stadium : 'İsmet Paşa Stadı',
                    'date': Timestamp.fromDate(matchDateTime),
                  });
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SKOR GÜNCELLEME
  Future<void> _updateScore(String matchId, Map<String, dynamic> data) async {
    final result = await _showScoreDialog();
    if (result == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('maclar')
          .doc(matchId)
          .update({
        'skor': {
          'ev_sahibi': result['homeScore'],
          'deplasman': result['awayScore'],
        },
        'bitis_tarihi': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Maç skoru güncellendi');

    } catch (e) {
      _showErrorSnackBar('Skor güncellenirken hata oluştu: $e');
    }
  }

  // ✅ SKOR DIALOG'U
  Future<Map<String, int>?> _showScoreDialog() async {
    final TextEditingController homeScoreController = TextEditingController();
    final TextEditingController awayScoreController = TextEditingController();

    return await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maç Skoru'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: homeScoreController,
                decoration: const InputDecoration(
                  labelText: 'Ev Sahibi',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('-', style: TextStyle(fontSize: 24)),
            ),
            Expanded(
              child: TextField(
                controller: awayScoreController,
                decoration: const InputDecoration(
                  labelText: 'Deplasman',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final homeScore = int.tryParse(homeScoreController.text) ?? 0;
              final awayScore = int.tryParse(awayScoreController.text) ?? 0;
              Navigator.pop(context, {
                'homeScore': homeScore,
                'awayScore': awayScore,
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // ✅ MAÇ SİLME
  Future<void> _deleteMatch(String matchId) async {
    final confirmed = await _showConfirmDialog(
      'Bu maçı silmek istediğinizden emin misiniz?',
    );

    if (confirmed) {
      try {
        await FirebaseFirestore.instance
            .collection('maclar')
            .doc(matchId)
            .delete();

        _showSuccessSnackBar('Maç başarıyla silindi');

      } catch (e) {
        _showErrorSnackBar('Silinirken hata oluştu: $e');
      }
    }
  }

  // ✅ TARİH FORMATLAMA
  String _formatDate(DateTime? date) {
    if (date == null) return 'Tarih yok';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // DİĞER MEVCUT METODLAR (değişmez)

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FutureBuilder<Map<String, int>>(
            future: AdminService.getAdminStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final stats = snapshot.data!;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Kullanıcılar', stats['users'] ?? 0, Icons.people)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Haberler', stats['news'] ?? 0, Icons.article)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Oyuncular', stats['players'] ?? 0, Icons.sports)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Maçlar', stats['matches'] ?? 0, Icons.sports_soccer)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryGreen),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
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
                  backgroundImage: data['photoURL'] != null ? NetworkImage(data['photoURL']) : null,
                  child: data['photoURL'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(data['displayName'] ?? 'İsim yok'),
                subtitle: Text(data['email'] ?? 'E-posta yok'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('haberler').snapshots(),
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
                leading: data['resimUrl'] != null
                    ? Image.network(data['resimUrl'], width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.article),
                title: Text(data['baslik'] ?? 'Başlık yok'),
                subtitle: Text(data['aciklama'] ?? 'Açıklama yok'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('oyuncular').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Henüz oyuncu eklenmemiş',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['foto'] != null && data['foto'].isNotEmpty
                      ? NetworkImage(data['foto'])
                      : null,
                  backgroundColor: const Color(0xFF00A651),
                  child: data['foto'] == null || data['foto'].isEmpty
                      ? Text(
                    '${data['numara'] ?? '?'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                title: Text(
                  data['isim'] ?? 'İsim yok',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${data['pozisyon'] ?? 'Pozisyon yok'} - Forma: ${data['numara'] ?? '?'}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),

                // ✅ POPUP MENU
                trailing: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                  onSelected: (action) => _handlePlayerAction(action, doc.id, data),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF00A651)),
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
                          Text('Sil'),
                        ],
                      ),
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

  Widget _buildTeamPhotosTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addTeamPhotoWithUrl,
            icon: const Icon(Icons.link),
            label: const Text('URL ile Fotoğraf Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('team_photos')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Henüz fotoğraf yok', style: TextStyle(fontSize: 18, color: Colors.grey)),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final photo = snapshot.data!.docs[index];
                  final data = photo.data() as Map<String, dynamic>;
                  final imageUrl = data['image_url'] as String? ?? '';
                  final title = data['title'] as String? ?? 'Başlık yok';

                  return Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                              : Container(color: Colors.grey.shade300, child: const Icon(Icons.image)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addTeamPhotoWithUrl() async {
    final result = await _showAddPhotoUrlDialog();
    if (result == null) return;

    try {
      await FirebaseFirestore.instance.collection('team_photos').add({
        'title': result['title']!.trim(),
        'image_url': result['url']!.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'created_by': FirebaseAuth.instance.currentUser?.email ?? 'Admin',
      });

      _showSuccessSnackBar('Fotoğraf başarıyla eklendi');

    } catch (e) {
      _showErrorSnackBar('Fotoğraf eklenirken hata oluştu: $e');
    }
  }

  Future<Map<String, String>?> _showAddPhotoUrlDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL ile Fotoğraf Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Fotoğraf Başlığı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Fotoğraf URL\'si',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final url = urlController.text.trim();
              if (title.isNotEmpty && url.isNotEmpty) {
                Navigator.pop(context, {'title': title, 'url': url});
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Evet'),
          ),
        ],
      ),
    ) ?? false;
  }
  void _handlePlayerAction(String action, String playerId, Map<String, dynamic> playerData) async {
    switch (action) {
      case 'edit':
        _showEditPlayerDialog(playerId, playerData);
        break;
      case 'delete':
        final confirm = await _showConfirmDialog('Bu oyuncuyu silmek istediğinizden emin misiniz?');
        if (confirm) {
          try {
            await FirebaseFirestore.instance.collection('oyuncular').doc(playerId).delete();
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
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  void _showEditPlayerDialog(String playerId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['isim'] ?? '');
    final numberController = TextEditingController(text: (currentData['numara'] ?? '').toString());
    final photoController = TextEditingController(text: currentData['foto'] ?? '');
    final flagController = TextEditingController(text: currentData['bayrak'] ?? '');
    String selectedPosition = currentData['pozisyon'] ?? 'Forvet';

    final positions = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFF00A651)),
            const SizedBox(width: 8),
            const Text('Oyuncu Düzenle', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Oyuncu Adı',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00A651)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: 'Forma Numarası',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00A651)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedPosition,
                decoration: InputDecoration(
                  labelText: 'Pozisyon',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00A651)),
                  ),
                ),
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                items: positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedPosition = value!;
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: photoController,
                decoration: InputDecoration(
                  labelText: 'Fotoğraf URL (İsteğe Bağlı)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00A651)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: flagController,
                decoration: InputDecoration(
                  labelText: 'Bayrak URL (İsteğe Bağlı)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00A651)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final numberText = numberController.text.trim();
              final photo = photoController.text.trim();
              final flag = flagController.text.trim();

              if (name.isNotEmpty && numberText.isNotEmpty) {
                final number = int.tryParse(numberText);
                if (number != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('oyuncular')
                        .doc(playerId)
                        .update({
                      'isim': name,
                      'numara': number,
                      'pozisyon': selectedPosition,
                      'foto': photo,
                      'bayrak': flag,
                      'guncelleme_tarihi': Timestamp.now(),
                    });

                    await AdminService.logAdminActivity(
                      action: 'PLAYER_UPDATED',
                      targetType: 'PLAYER',
                      targetId: playerId,
                      details: {'playerName': name},
                    );

                    Navigator.pop(context);
                    _showSuccessSnackBar('Oyuncu güncellendi: $name');
                  } catch (e) {
                    _showErrorSnackBar('Güncelleme hatası: $e');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
            ),
            child: const Text('Güncelle', style: TextStyle(color: Colors.white)),
          ),
        ],
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
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature özelliği yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ✅ BU FONKSİYONU EKLEYİN:
  void _showAddNewsDialog() {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final contentController = TextEditingController();
    final imageController = TextEditingController();
    final authorController = TextEditingController();
    String selectedCategory = 'Genel';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A), // Kocaelispor siyahı
          title: Row(
            children: [
              Icon(Icons.article, color: const Color(0xFF00A651)),
              const SizedBox(width: 8),
              const Text('Yeni Haber Ekle', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Başlık
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Başlık *',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00A651)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Kategori
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00A651)),
                      ),
                    ),
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white),
                    items: ['Genel', 'Maç', 'Transfer', 'Antrenman', 'Kulüp']
                        .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(color: Colors.white)),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Özet
                  TextField(
                    controller: summaryController,
                    decoration: InputDecoration(
                      labelText: 'Özet',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00A651)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // İçerik
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: 'İçerik *',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00A651)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),

                  // Resim URL
                  TextField(
                    controller: imageController,
                    decoration: InputDecoration(
                      labelText: 'Resim URL (İsteğe Bağlı)',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00A651)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Yazar
                  TextField(
                    controller: authorController,
                    decoration: InputDecoration(
                      labelText: 'Yazar',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00A651)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: Colors.grey.shade400)),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  _showErrorSnackBar('Başlık ve İçerik zorunludur!');
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('haberler').add({
                    'baslik': title,
                    'kategori': selectedCategory,
                    'ozet': summaryController.text.trim(),
                    'icerik': content,
                    'resimUrl': imageController.text.trim(),
                    'yazar': authorController.text.trim().isEmpty
                        ? 'Admin'
                        : authorController.text.trim(),
                    'tarih': Timestamp.now(),
                    'olusturanAdmin': FirebaseAuth.instance.currentUser?.email,
                  });

                  await AdminService.logAdminActivity(
                    action: 'NEWS_CREATED',
                    targetType: 'NEWS',
                    details: {
                      'title': title,
                      'category': selectedCategory,
                    },
                  );

                  Navigator.pop(context);
                  _showSuccessSnackBar('Haber başarıyla eklendi!');

                } catch (e) {
                  _showErrorSnackBar('Haber eklenemedi: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
              ),
              child: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

} // ← Class kapanış parant