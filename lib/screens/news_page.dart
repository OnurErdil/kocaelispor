// lib/screens/news_page.dart - Admin Kontrollü Versiyon
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _kategoriler = ['Tümü', 'Maç', 'Transfer', 'Antrenman', 'Kulüp'];

  // Admin kontrolü için
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kategoriler.length, vsync: this);
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Admin durumunu kontrol et
  Future<void> _checkAdminStatus() async {
    try {
      final adminStatus = await AdminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = adminStatus;
        _isCheckingAdmin = false;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Haberler",
      ),
      // FloatingActionButton sadece admin için göster
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        onPressed: () => _showAddNewsDialog(),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Haber Ekle (Admin)',
      )
          : null,
      body: Column(
        children: [
          // Admin kontrolü yüklenirken loading göster
          if (_isCheckingAdmin)
            Container(
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Yetki kontrol ediliyor...',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Admin için bilgi çubuğu
          if (!_isCheckingAdmin && _isAdmin)
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Yönetici modundasınız',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Kategori tabları
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey,
              tabs: _kategoriler.map((kategori) => Tab(text: kategori)).toList(),
            ),
          ),

          // Haber listesi
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _kategoriler.map((kategori) => _buildNewsList(kategori)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(String kategori) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('haberler')
        .orderBy('tarih', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Haberler yüklenirken hata oluştu: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
                SizedBox(height: 16),
                Text('Haberler yükleniyor...'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget(kategori);
        }

        final haberler = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return kategori == 'Tümü' || data['kategori'] == kategori;
        }).toList();

        if (haberler.isEmpty) {
          return _buildEmptyWidget(kategori);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: haberler.length,
            itemBuilder: (context, index) {
              final haber = haberler[index].data() as Map<String, dynamic>;
              return _buildNewsCard(haber, haberler[index].id);
            },
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> haber, String haberId) {
    final tarih = haber['tarih'] as Timestamp?;
    final formattedDate = tarih != null
        ? "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}"
        : 'Tarih yok';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showNewsDetail(haber, haberId),
        onLongPress: _isAdmin ? () => _showAdminOptions(haberId, haber) : null, // Admin için uzun basma
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin etiketi (varsa)
            if (_isAdmin)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Düzenlemek için uzun basın',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Haber resmi (varsa)
            if (haber['resimUrl'] != null && haber['resimUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: _isAdmin ? Radius.zero : const Radius.circular(12),
                  topRight: _isAdmin ? Radius.zero : const Radius.circular(12),
                ),
                child: Image.network(
                  haber['resimUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori etiketi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getKategoriColor(haber['kategori'] ?? 'Genel'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      haber['kategori'] ?? 'Genel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Başlık
                  Text(
                    haber['baslik'] ?? 'Başlık Yok',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Özet
                  if (haber['ozet'] != null)
                    Text(
                      haber['ozet'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Tarih ve yazar
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (haber['yazar'] != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          haber['yazar'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Admin seçenekleri menüsü
  void _showAdminOptions(String haberId, Map<String, dynamic> haber) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Admin İşlemleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Düzenle
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue.shade600),
              title: const Text('Haberi Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _showEditNewsDialog(haberId, haber);
              },
            ),

            // Sil
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade600),
              title: const Text('Haberi Sil'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteNews(haberId, haber['baslik'] ?? 'Bu haber');
              },
            ),

            // İptal
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Haber silme onayı
  void _confirmDeleteNews(String haberId, String haberBaslik) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haberi Sil'),
        content: Text('\"$haberBaslik\" başlıklı haberi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteNews(haberId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // Haber silme işlemi
  Future<void> _deleteNews(String haberId) async {
    try {
      await FirebaseFirestore.instance.collection('haberler').doc(haberId).delete();

      // Admin log kaydı
      await AdminService.logAdminActivity(
        action: 'NEWS_DELETED',
        targetType: 'NEWS',
        targetId: haberId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Haber başarıyla silindi'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Haber silinemedi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyWidget(String kategori) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            kategori == 'Tümü'
                ? 'Henüz haber yok'
                : '$kategori kategorisinde haber yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAdmin ? 'İlk haberi siz ekleyin!' : 'Yakında haberler eklenecek!',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori) {
      case 'Maç':
        return Colors.red.shade600;
      case 'Transfer':
        return Colors.blue.shade600;
      case 'Antrenman':
        return Colors.orange.shade600;
      case 'Kulüp':
        return AppTheme.primaryGreen;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showNewsDetail(Map<String, dynamic> haber, String haberId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Admin için düzenle butonu
              if (_isAdmin)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.orange.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Yönetici Görünümü',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditNewsDialog(haberId, haber);
                        },
                        icon: Icon(Icons.edit, color: Colors.orange.shade700),
                        tooltip: 'Düzenle',
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Haber resmi
                      if (haber['resimUrl'] != null && haber['resimUrl'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            haber['resimUrl'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Kategori
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getKategoriColor(haber['kategori'] ?? 'Genel'),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          haber['kategori'] ?? 'Genel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Başlık
                      Text(
                        haber['baslik'] ?? 'Başlık Yok',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tarih ve yazar
                      Row(
                        children: [
                          Text(
                            (haber['tarih'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Tarih yok',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (haber['yazar'] != null) ...[
                            const SizedBox(width: 16),
                            Text(
                              '• ${haber['yazar']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // İçerik
                      Text(
                        haber['icerik'] ?? haber['ozet'] ?? 'İçerik bulunamadı.',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Haber ekleme dialogu (devamında _showEditNewsDialog ile birlikte olacak)
  void _showAddNewsDialog() {
    _showNewsDialog(isEdit: false);
  }

  void _showEditNewsDialog(String haberId, Map<String, dynamic> haberData) {
    _showNewsDialog(isEdit: true, haberId: haberId, existingData: haberData);
  }

  // Birleşik haber ekleme/düzenleme dialogu
  void _showNewsDialog({
    required bool isEdit,
    String? haberId,
    Map<String, dynamic>? existingData,
  }) {
    final titleController = TextEditingController(text: existingData?['baslik'] ?? '');
    final summaryController = TextEditingController(text: existingData?['ozet'] ?? '');
    final contentController = TextEditingController(text: existingData?['icerik'] ?? '');
    final imageController = TextEditingController(text: existingData?['resimUrl'] ?? '');
    final authorController = TextEditingController(text: existingData?['yazar'] ?? '');
    String selectedCategory = existingData?['kategori'] ?? 'Genel';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Haberi Düzenle' : 'Yeni Haber Ekle'),
          content: SizedBox(
            width: double.maxFinite,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Genel', 'Maç', 'Transfer', 'Antrenman', 'Kulüp']
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: summaryController,
                    decoration: const InputDecoration(
                      labelText: 'Özet',
                      border: OutlineInputBorder(),
                      hintText: 'Kısa özet (opsiyonel)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'İçerik *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Resim URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/image.jpg (opsiyonel)',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'Yazar',
                      border: OutlineInputBorder(),
                      hintText: 'Haber yazarı (opsiyonel)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Başlık ve içerik zorunludur!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                if (isEdit && haberId != null) {
                  await _updateNews(haberId, {
                    'baslik': title,
                    'kategori': selectedCategory,
                    'ozet': summaryController.text.trim(),
                    'icerik': content,
                    'resimUrl': imageController.text.trim(),
                    'yazar': authorController.text.trim(),
                    'guncellemeTarihi': FieldValue.serverTimestamp(),
                  });
                } else {
                  await _addNews({
                    'baslik': title,
                    'kategori': selectedCategory,
                    'ozet': summaryController.text.trim(),
                    'icerik': content,
                    'resimUrl': imageController.text.trim(),
                    'yazar': authorController.text.trim(),
                    'tarih': FieldValue.serverTimestamp(),
                    'olusturanAdmin': FirebaseAuth.instance.currentUser?.email,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  // Haber ekleme işlemi
  Future<void> _addNews(Map<String, dynamic> newsData) async {
    try {
      await FirebaseFirestore.instance.collection('haberler').add(newsData);

      // Admin log kaydı
      await AdminService.logAdminActivity(
        action: 'NEWS_CREATED',
        targetType: 'NEWS',
        details: {
          'title': newsData['baslik'],
          'category': newsData['kategori'],
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Haber başarıyla eklendi!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Haber eklenemedi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Haber güncelleme işlemi
  Future<void> _updateNews(String haberId, Map<String, dynamic> newsData) async {
    try {
      await FirebaseFirestore.instance.collection('haberler').doc(haberId).update(newsData);

      // Admin log kaydı
      await AdminService.logAdminActivity(
        action: 'NEWS_UPDATED',
        targetType: 'NEWS',
        targetId: haberId,
        details: {
          'title': newsData['baslik'],
          'category': newsData['kategori'],
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Haber başarıyla güncellendi!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Haber güncellenemedi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}