// lib/screens/galeri_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../models/foto_model.dart';
import '../theme/app_theme.dart';
import 'foto_detay_sayfasi.dart'; // Bu satırı dosyanın üstüne ekleyin

class GaleriSayfasi extends StatefulWidget {
  const GaleriSayfasi({super.key});

  @override
  State<GaleriSayfasi> createState() => _GaleriSayfasiState();
}

class _GaleriSayfasiState extends State<GaleriSayfasi> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _kategoriler = ['Tümü', 'Maç', 'Antrenman', 'Taraftar', 'Stadyum', 'Oyuncular', 'Kutlama'];

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
        title: "Fotoğraf Galerisi",
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPhotoDialog(),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
        tooltip: 'Fotoğraf Ekle',
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

          // Fotoğraf grid'i
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _kategoriler.map((kategori) => _buildPhotoGrid(kategori)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(String kategori) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('fotograflar')
        .orderBy('tarih', descending: true)
        .limit(100);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
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
                Text('Fotoğraflar yükleniyor...'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  kategori == 'Tümü'
                      ? 'Henüz fotoğraf yok'
                      : '$kategori kategorisinde fotoğraf yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'İlk fotoğrafı siz ekleyin!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final fotograflar = snapshot.data!.docs
            .map((doc) => Foto.fromFirestore(doc))
            .where((foto) => kategori == 'Tümü' || foto.kategori == kategori)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: fotograflar.length,
            itemBuilder: (context, index) {
              final foto = fotograflar[index];
              return _buildPhotoCard(foto);
            },
          ),
        );
      },
    );
  }

  Widget _buildPhotoCard(Foto foto) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FotoDetaySayfasi(
                fotoUrl: foto.url,
                oyuncuAdi: foto.baslik,
                pozisyon: foto.kategori,
                formaNo: 0,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      foto.url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          ),
                        );
                      },
                    ),

                    // Kategori etiketi
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Foto.getKategoriColor(foto.kategori).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Foto.getKategoriIcon(foto.kategori),
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              foto.kategori,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Beğeni sayısı
                    if (foto.begeniSayisi > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 12,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${foto.begeniSayisi}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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

            // Alt bilgiler
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foto.baslik,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            foto.formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final photographerController = TextEditingController();
    final urlController = TextEditingController();
    String selectedCategory = 'Genel';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Fotoğraf Ekle'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Fotoğraf URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/photo.jpg',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (İsteğe bağlı)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Genel', 'Maç', 'Antrenman', 'Taraftar', 'Stadyum', 'Oyuncular', 'Kutlama']
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
                    controller: photographerController,
                    decoration: const InputDecoration(
                      labelText: 'Fotoğrafçı (İsteğe bağlı)',
                      border: OutlineInputBorder(),
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
                if (urlController.text.trim().isEmpty ||
                    titleController.text.trim().isEmpty) {
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('fotograflar').add({
                    'url': urlController.text.trim(),
                    'baslik': titleController.text.trim(),
                    'aciklama': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    'kategori': selectedCategory,
                    'fotografci': photographerController.text.trim().isEmpty
                        ? null
                        : photographerController.text.trim(),
                    'tarih': FieldValue.serverTimestamp(),
                    'etiketler': [],
                    'begeniSayisi': 0,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fotoğraf başarıyla eklendi!')),
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