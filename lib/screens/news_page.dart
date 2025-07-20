// lib/screens/news_page.dart - ANASAYFA GİBİ GÜZEL RENK TASARIMI
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
      // 🎨 KOYU ARKA PLAN - Anasayfa gibi
      backgroundColor: const Color(0xFF121212),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Daha yüksek AppBar
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade800,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 🎨 Üst kısım - Anasayfa gibi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // 🎨 Sol taraf - Logo ve başlık
                      Row(
                        children: [
                          // Top logosu (ileride değişecek)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00913C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Başlık ve alt yazı
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HABERLER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Kocaelispor Taraftar Uygulaması',
                                style: TextStyle(
                                  color: Colors.green.shade400,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🎨 Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF00913C), // Kocaelispor yeşili
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF00913C),
                    unselectedLabelColor: Colors.grey.shade400,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: _kategoriler.map((kategori) => Tab(text: kategori)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // FloatingActionButton sadece admin için göster - 🎨 Yeşil tema
      floatingActionButton: _isAdmin
          ? Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00913C), // Kocaelispor yeşili
              Color(0xFF007A32), // Daha koyu yeşil
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00913C).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddNewsDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      )
          : null,

      body: TabBarView(
        controller: _tabController,
        children: _kategoriler.map((kategori) => _buildNewsTab(kategori)).toList(),
      ),
    );
  }

  Widget _buildNewsTab(String kategori) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('haberler')
          .orderBy('tarih', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Haberler yüklenirken hata oluştu: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
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
          // 🎨 Refresh indicator'ı yeşil yap
          color: const Color(0xFF00913C),
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            // 🎨 Koyu arka plan için padding
            padding: const EdgeInsets.all(16),
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

  // 🎨 Yükleme widget'ı - koyu tema
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00913C)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Haberler yükleniyor...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Haber kartı - anasayfa gibi güzel tasarım
  Widget _buildNewsCard(Map<String, dynamic> haber, String haberId) {
    final tarih = haber['tarih'] as Timestamp?;
    final formattedDate = tarih != null
        ? "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}"
        : 'Tarih yok';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // 🎨 Koyu kart arka planı
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNewsDetail(haber, haberId),
          onLongPress: _isAdmin ? () => _showNewsOptions(haberId, haber) : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎨 Haber resmi - köşeleri yuvarla
              if (haber['resimUrl'] != null && haber['resimUrl'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        haber['resimUrl'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                      // 🎨 Gradient overlay - daha iyi okunabilirlik
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎨 Kategori etiketi - yeşil tema
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getKategoriColor(haber['kategori'] ?? 'Genel'),
                            _getKategoriColor(haber['kategori'] ?? 'Genel').withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getKategoriColor(haber['kategori'] ?? 'Genel').withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                    const SizedBox(height: 12),

                    // 🎨 Başlık - beyaz renk
                    Text(
                      haber['baslik'] ?? 'Başlık Yok',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // 🎨 Özet - gri renk
                    if (haber['ozet'] != null)
                      Text(
                        haber['ozet'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),

                    // 🎨 Alt bilgiler - tarih ve okuma butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        // 🎨 Okuma butonu - yeşil tema
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00913C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00913C).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Oku',
                                style: TextStyle(
                                  color: Color(0xFF00913C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: const Color(0xFF00913C),
                              ),
                            ],
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
      ),
    );
  }

  // 🎨 Boş widget - koyu tema
  Widget _buildEmptyWidget(String kategori) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            kategori == 'Tümü'
                ? 'Henüz haber yok'
                : '$kategori kategorisinde haber yok',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAdmin ? 'İlk haberi siz ekleyin!' : 'Yakında haberler eklenecek!',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Hata widget'ı - koyu tema
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00913C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kategori renklerini güncelle - anasayfa teması ile uyumlu
  Color _getKategoriColor(String kategori) {
    switch (kategori) {
      case 'Maç':
        return const Color(0xFFE53E3E); // Kırmızı
      case 'Transfer':
        return const Color(0xFF3182CE); // Mavi
      case 'Antrenman':
        return const Color(0xFFD69E2E); // Turuncu
      case 'Kulüp':
        return const Color(0xFF00913C); // Kocaelispor yeşili
      default:
        return Colors.grey.shade600;
    }
  }

  // Haber detay sayfası - koyu tema
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
            // 🎨 Koyu arka plan
            color: Color(0xFF121212),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 🎨 Handle bar - daha güzel
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Admin butonları - 🎨 Koyu tema
              if (_isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteNews(haberId, haber['baslik'] ?? 'Bu haber');
                        },
                        icon: Icon(Icons.delete, color: Colors.red.shade400),
                        tooltip: 'Sil',
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditNewsDialog(haberId, haber);
                        },
                        icon: Icon(Icons.edit, color: const Color(0xFF00913C)),
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
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            haber['resimUrl'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // 🎨 Kategori - güzel tasarım
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getKategoriColor(haber['kategori'] ?? 'Genel'),
                              _getKategoriColor(haber['kategori'] ?? 'Genel').withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
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
                      const SizedBox(height: 16),

                      // 🎨 Başlık - beyaz renk
                      Text(
                        haber['baslik'] ?? 'Başlık Yok',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🎨 Tarih ve yazar - gri renk
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (haber['tarih'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Tarih yok',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          if (haber['yazar'] != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              haber['yazar'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🎨 İçerik - beyaz renk, güzel formatla
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: Text(
                          haber['icerik'] ?? haber['ozet'] ?? 'İçerik bulunamadı.',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white,
                          ),
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

  // Diğer metodlar (admin işlemleri) aynı kalacak...
  void _showNewsOptions(String haberId, Map<String, dynamic> haber) {
    // Admin seçenekleri göster
  }

  void _showAddNewsDialog() {
    // Haber ekleme dialogu
  }

  void _showEditNewsDialog(String haberId, Map<String, dynamic> haberData) {
    // Haber düzenleme dialogu
  }

  void _confirmDeleteNews(String haberId, String haberBaslik) {
    // Haber silme onayı
  }
}