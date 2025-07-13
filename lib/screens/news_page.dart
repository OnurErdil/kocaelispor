// lib/screens/news_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _kategoriler = ['Tümü', 'Maç', 'Transfer', 'Antrenman', 'Kulüp'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kategoriler.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Haberler",
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNewsDialog(),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Haber Ekle',
      ),
      body: Column(
        children: [
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
                const SizedBox(height: 16),
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
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Haber resmi (varsa)
            if (haber['resimUrl'] != null && haber['resimUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
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
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),

                  // Alt bilgiler
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
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

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
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
            'İlk haberi siz ekleyin!',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
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

                      // Tarih
                      Text(
                        (haber['tarih'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Tarih yok',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
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

  void _showAddNewsDialog() {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final contentController = TextEditingController();
    final imageController = TextEditingController();
    String selectedCategory = 'Genel';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Haber Ekle'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
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
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'İçerik',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Resim URL (İsteğe bağlı)',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/image.jpg',
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
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('haberler').add({
                    'baslik': titleController.text.trim(),
                    'ozet': summaryController.text.trim().isEmpty
                        ? null
                        : summaryController.text.trim(),
                    'icerik': contentController.text.trim(),
                    'kategori': selectedCategory,
                    'resimUrl': imageController.text.trim().isEmpty
                        ? null
                        : imageController.text.trim(),
                    'tarih': FieldValue.serverTimestamp(),
                    'goruntulemeSayisi': 0,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Haber başarıyla eklendi!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}