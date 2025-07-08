// lib/screens/haberler_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class HaberlerSayfasi extends StatefulWidget {
  const HaberlerSayfasi({super.key});

  @override
  State<HaberlerSayfasi> createState() => _HaberlerSayfasiState();
}

class _HaberlerSayfasiState extends State<HaberlerSayfasi> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = ['Tümü', 'Transfer', 'Maç', 'Kulüp', 'Altyapı'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
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
        title: "Haberler",
        showBackButton: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return _buildNewsTab(category);
        }).toList(),
      ),
      floatingActionButton: _buildAdminFAB(),
    );
  }

  Widget _buildNewsTab(String category) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('haberler')
        .orderBy('tarih', descending: true);

    if (category != 'Tümü') {
      query = query.where('kategori', isEqualTo: category);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(20).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.newspaper, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  '$category kategorisinde haber bulunmuyor',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final haber = doc.data() as Map<String, dynamic>;
              return _buildNewsCard(haber, doc.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> haber, String haberId) {
    final tarih = (haber['tarih'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = "${tarih.day}.${tarih.month}.${tarih.year}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openNewsDetail(haber, haberId),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel
            if (haber['gorselUrl'] != null && haber['gorselUrl'].isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    haber['gorselUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori ve Tarih
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          haber['kategori'] ?? 'Genel',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Başlık
                  Text(
                    haber['baslik'] ?? 'Başlıksız Haber',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Özet
                  Text(
                    haber['ozet'] ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Okuma süresi ve detay
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${_calculateReadTime(haber['icerik'] ?? '')} dk okuma',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Devamını oku →',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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

  int _calculateReadTime(String content) {
    const wordsPerMinute = 200;
    final wordCount = content.split(' ').length;
    return (wordCount / wordsPerMinute).ceil();
  }

  void _openNewsDetail(Map<String, dynamic> haber, String haberId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HaberDetaySayfasi(haber: haber, haberId: haberId),
      ),
    );
  }

  Widget? _buildAdminFAB() {
    // Admin kontrolü yapılmalı
    return FloatingActionButton(
      onPressed: () => _showAddNewsDialog(),
      child: const Icon(Icons.add),
    );
  }

  void _showAddNewsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HaberEkleForm(),
    );
  }
}

// Haber Detay Sayfası
class HaberDetaySayfasi extends StatelessWidget {
  final Map<String, dynamic> haber;
  final String haberId;

  const HaberDetaySayfasi({
    super.key,
    required this.haber,
    required this.haberId,
  });

  @override
  Widget build(BuildContext context) {
    final tarih = (haber['tarih'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = "${tarih.day}.${tarih.month}.${tarih.year} ${tarih.hour}:${tarih.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: haber['gorselUrl'] != null
                  ? Image.network(
                haber['gorselUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.broken_image, size: 64),
                  );
                },
              )
                  : Container(
                color: AppTheme.primaryGreen,
                child: const Icon(Icons.newspaper, size: 64, color: Colors.white),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori ve Tarih
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          haber['kategori'] ?? 'Genel',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Başlık
                  Text(
                    haber['baslik'] ?? 'Başlıksız Haber',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Özet
                  if (haber['ozet'] != null && haber['ozet'].isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: AppTheme.primaryGreen,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Text(
                        haber['ozet'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // İçerik
                  Text(
                    haber['icerik'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Paylaş butonu
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Paylaşma işlemi
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Haberi Paylaş'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Haber Ekleme Formu
class HaberEkleForm extends StatefulWidget {
  const HaberEkleForm({super.key});

  @override
  State<HaberEkleForm> createState() => _HaberEkleFormState();
}

class _HaberEkleFormState extends State<HaberEkleForm> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _ozetController = TextEditingController();
  final _icerikController = TextEditingController();
  final _gorselUrlController = TextEditingController();

  String _selectedKategori = 'Kulüp';
  bool _isLoading = false;

  @override
  void dispose() {
    _baslikController.dispose();
    _ozetController.dispose();
    _icerikController.dispose();
    _gorselUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('haberler').add({
        'baslik': _baslikController.text.trim(),
        'ozet': _ozetController.text.trim(),
        'icerik': _icerikController.text.trim(),
        'gorselUrl': _gorselUrlController.text.trim(),
        'kategori': _selectedKategori,
        'tarih': Timestamp.now(),
        'okunmaSayisi': 0,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Haber başarıyla eklendi!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yeni Haber Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori seçimi
                    DropdownButtonFormField<String>(
                      value: _selectedKategori,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Transfer', 'Maç', 'Kulüp', 'Altyapı']
                          .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedKategori = value!),
                    ),
                    const SizedBox(height: 16),

                    // Başlık
                    TextFormField(
                      controller: _baslikController,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Başlık gerekli' : null,
                    ),
                    const SizedBox(height: 16),

                    // Özet
                    TextFormField(
                      controller: _ozetController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Özet',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Özet gerekli' : null,
                    ),
                    const SizedBox(height: 16),

                    // İçerik
                    TextFormField(
                      controller: _icerikController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'İçerik',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'İçerik gerekli' : null,
                    ),
                    const SizedBox(height: 16),

                    // Görsel URL
                    TextFormField(
                      controller: _gorselUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Görsel URL (Opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveNews,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Haberi Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}