// lib/screens/admin_panel_screen.dart - MAÇ YÖNETİMİ EKLİ VERSİYON

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
    _tabController = TabController(length: 7, vsync: this); // 7 sekme oldu
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
                Tab(icon: Icon(Icons.sports_soccer), text: "Maçlar"), // YENİ SEKME
                Tab(icon: Icon(Icons.photo_library), text: "Takım Fotoları"),
                Tab(icon: Icon(Icons.history), text: "Loglar"),
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
                _buildMatchesTab(), // YENİ SEKME İÇERİĞİ
                _buildTeamPhotosTab(),
                _buildLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // YENİ: Maçlar sekmesi
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
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Alt sekmeler
                Container(
                  color: Colors.grey.shade100,
                  child: const TabBar(
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: "Yaklaşan Maçlar"),
                      Tab(text: "Oynanmış Maçlar"),
                      Tab(text: "Tüm Maçlar"),
                    ],
                  ),
                ),

                // Alt sekme içerikleri
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUpcomingMatchesList(),
                      _buildFinishedMatchesList(),
                      _buildAllMatchesList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Yaklaşan maçlar listesi
  Widget _buildUpcomingMatchesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date', descending: false)
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
                Icon(Icons.schedule, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Yaklaşan maç yok',
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
            return _buildMatchCard(match, isUpcoming: true);
          },
        );
      },
    );
  }

  // Oynanmış maçlar listesi
  Widget _buildFinishedMatchesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('isFinished', isEqualTo: true)
          .orderBy('date', descending: true)
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
                  'Oynanmış maç yok',
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
            return _buildMatchCard(match, isFinished: true);
          },
        );
      },
    );
  }

  // Tüm maçlar listesi
  Widget _buildAllMatchesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .orderBy('date', descending: true)
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
            final data = match.data() as Map<String, dynamic>;
            final isFinished = data['isFinished'] ?? false;
            return _buildMatchCard(match, isFinished: isFinished, isUpcoming: !isFinished);
          },
        );
      },
    );
  }

  // Maç kartı
  Widget _buildMatchCard(DocumentSnapshot match, {bool isFinished = false, bool isUpcoming = false}) {
    final data = match.data() as Map<String, dynamic>;
    final homeTeam = data['homeTeam'] as String? ?? 'Ev Sahibi';
    final awayTeam = data['awayTeam'] as String? ?? 'Deplasman';
    final homeScore = data['homeScore']?.toString() ?? '0';
    final awayScore = data['awayScore']?.toString() ?? '0';
    final date = data['date'] as Timestamp?;
    final stadium = data['stadium'] as String? ?? 'Belirtilmemiş';
    final isHome = data['isHome'] as bool? ?? false;

    Color cardColor = Colors.white;
    if (isFinished) {
      cardColor = Colors.green.shade50;
    } else if (isUpcoming) {
      cardColor = Colors.blue.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Takım isimleri ve skor
            Row(
              children: [
                // Ev sahibi takım
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        homeTeam,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isHome ? Colors.green.shade700 : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isHome)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'EV SAHİBİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Skor veya VS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFinished ? Colors.green.shade700 : Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFinished ? '$homeScore - $awayScore' : 'VS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Deplasman takım
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        awayTeam,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: !isHome ? Colors.green.shade700 : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isHome)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'EV SAHİBİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tarih ve stad bilgisi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      date != null ? _formatDate(date.toDate()) : 'Tarih yok',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stadium, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      stadium,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // İşlem butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Düzenle butonu
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editMatch(match.id, data),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Düzenle'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade600),
                      foregroundColor: Colors.blue.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Skor güncelle butonu (sadece yaklaşan maçlar için)
                if (isUpcoming)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateScore(match.id, data),
                      icon: const Icon(Icons.score, size: 16),
                      label: const Text('Skor'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade600),
                        foregroundColor: Colors.green.shade600,
                      ),
                    ),
                  ),

                // Sonuç ekleme butonu (sadece yaklaşan maçlar için)
                if (isUpcoming)
                  const SizedBox(width: 8),

                // Sil butonu
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteMatch(match.id),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text(
                      'Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Maç ekleme fonksiyonu
  Future<void> _addMatch() async {
    final result = await _showAddMatchDialog();
    if (result == null) return;

    try {
      await FirebaseFirestore.instance.collection('matches').add({
        'homeTeam': result['homeTeam'],
        'awayTeam': result['awayTeam'],
        'date': result['date'],
        'stadium': result['stadium'],
        'isHome': result['isHome'],
        'isFinished': false,
        'homeScore': null,
        'awayScore': null,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': FirebaseAuth.instance.currentUser?.email ?? 'Bilinmeyen',
      });

      await AdminService.logAdminActivity(
        action: 'MATCH_ADDED',
        targetType: 'MATCH',
        targetId: result['homeTeam'] + ' vs ' + result['awayTeam'],
      );

      _showSuccessSnackBar('Maç başarıyla eklendi');

    } catch (e) {
      _showErrorSnackBar('Maç eklenirken hata oluştu: $e');
    }
  }

  // Maç ekleme dialog'u
  Future<Map<String, dynamic>?> _showAddMatchDialog() async {
    final TextEditingController homeTeamController = TextEditingController();
    final TextEditingController awayTeamController = TextEditingController();
    final TextEditingController stadiumController = TextEditingController();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 15, minute: 0);
    bool isHome = true;

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

                // Kocaelispor ev sahibi mi?
                SwitchListTile(
                  title: const Text('Kocaelispor ev sahibi mi?'),
                  value: isHome,
                  onChanged: (value) => setState(() => isHome = value),
                  activeColor: Colors.green.shade700,
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
                    'isHome': isHome,
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

  // Maç düzenleme
  Future<void> _editMatch(String matchId, Map<String, dynamic> data) async {
    // Benzer dialog ile maç bilgilerini düzenleme
    _showSuccessSnackBar('Maç düzenleme özelliği yakında eklenecek');
  }

  // Skor güncelleme
  Future<void> _updateScore(String matchId, Map<String, dynamic> data) async {
    final result = await _showScoreDialog();
    if (result == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'homeScore': result['homeScore'],
        'awayScore': result['awayScore'],
        'isFinished': true,
        'finished_at': FieldValue.serverTimestamp(),
      });

      await AdminService.logAdminActivity(
        action: 'MATCH_SCORE_UPDATED',
        targetType: 'MATCH',
        targetId: matchId,
      );

      _showSuccessSnackBar('Maç skoru güncellendi');

    } catch (e) {
      _showErrorSnackBar('Skor güncellenirken hata oluştu: $e');
    }
  }

  // Skor dialog'u
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

  // Maç silme
  Future<void> _deleteMatch(String matchId) async {
    final confirmed = await _showConfirmDialog(
      'Bu maçı silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
    );

    if (confirmed) {
      try {
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .delete();

        await AdminService.logAdminActivity(
          action: 'MATCH_DELETED',
          targetType: 'MATCH',
          targetId: matchId,
        );

        _showSuccessSnackBar('Maç başarıyla silindi');

      } catch (e) {
        _showErrorSnackBar('Silinirken hata oluştu: $e');
      }
    }
  }

  // Tarih formatlama
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // DİĞER MEVCUT METODLAR (değişmeden kalacak - takım fotoları vs.)

  Widget _buildTeamPhotosTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                kIsWeb ? 'Web Platformu Tespit Edildi' : 'Mobil Platform',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fotoğraf yükleme özelliği mobil platformlarda çalışır.\n'
                    'Şimdilik manuel olarak URL ile fotoğraf ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton.icon(
            onPressed: _addTeamPhotoWithUrl,
            icon: const Icon(Icons.link),
            label: const Text('URL ile Fotoğraf Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 16),

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

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Hata: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Henüz takım fotoğrafı yok',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Yukarıdaki butona tıklayarak fotoğraf ekleyebilirsiniz',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final photos = snapshot.data!.docs;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final data = photo.data() as Map<String, dynamic>;
                  final imageUrl = data['image_url'] as String? ?? '';
                  final title = data['title'] as String? ?? 'Başlık yok';

                  return Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            child: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                                : Container(color: Colors.grey.shade300, child: const Icon(Icons.image)),
                          ),
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

  // URL ile fotoğraf ekleme
  Future<void> _addTeamPhotoWithUrl() async {
    final result = await _showAddPhotoUrlDialog();
    if (result == null) return;

    final title = result['title']!;
    final imageUrl = result['url']!;

    try {
      await FirebaseFirestore.instance.collection('team_photos').add({
        'title': title.trim(),
        'image_url': imageUrl.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'created_by': FirebaseAuth.instance.currentUser?.email ?? 'Bilinmeyen',
      });

      await AdminService.logAdminActivity(
        action: 'TEAM_PHOTO_ADDED',
        targetType: 'PHOTO',
        targetId: title,
      );

      _showSuccessSnackBar('Takım fotoğrafı başarıyla eklendi');

    } catch (e) {
      _showErrorSnackBar('Fotoğraf eklenirken hata oluştu: $e');
    }
  }

  // URL ile fotoğraf ekleme dialog'u
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
                hintText: 'Örn: Takım Antrenmanı',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Fotoğraf URL\'si',
                hintText: 'https://example.com/image.jpg',
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

  // DİĞER MEVCUT METODLAR

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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['fotoUrl'] != null ? NetworkImage(data['fotoUrl']) : null,
                  child: data['fotoUrl'] == null ? Text('${data['formaNo'] ?? '?'}') : null,
                ),
                title: Text(data['isim'] ?? 'İsim yok'),
                subtitle: Text('${data['pozisyon'] ?? 'Pozisyon yok'} - Forma: ${data['formaNo'] ?? '?'}'),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getActionIcon(String? action) {
    switch (action) {
      case 'MATCH_ADDED':
        return Icons.add_circle;
      case 'MATCH_SCORE_UPDATED':
        return Icons.score;
      case 'MATCH_DELETED':
        return Icons.delete;
      case 'TEAM_PHOTO_ADDED':
        return Icons.add_a_photo;
      default:
        return Icons.history;
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Evet'),
          ),
        ],
      ),
    ) ?? false;
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