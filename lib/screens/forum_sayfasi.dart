import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../models/forum_models.dart';

class ForumSayfasi extends StatefulWidget {
  const ForumSayfasi({super.key});

  @override
  State<ForumSayfasi> createState() => _ForumSayfasiState();
}

class _ForumSayfasiState extends State<ForumSayfasi> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeForum();
  }

  Future<void> _initializeForum() async {
    try {
      await _createDefaultCategories();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Forum başlatma hatası: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _createDefaultCategories() async {
    final firestore = FirebaseFirestore.instance;

    final categories = [
      {
        'id': 'genel',
        'ad': 'Genel Konular',
        'aciklama': 'Takımımız hakkında genel sohbet',
        'ikon': 'chat',
        'renk': 0xFF4CAF50,
        'sira': 1,
        'aktif': true,
        'konuSayisi': 0,
        'mesajSayisi': 0,
        'olusturmaTarihi': FieldValue.serverTimestamp(),
      },
      {
        'id': 'maclar',
        'ad': 'Maç Konuları',
        'aciklama': 'Oynanan ve oynanacak maçlar hakkında',
        'ikon': 'sports_soccer',
        'renk': 0xFF2196F3,
        'sira': 2,
        'aktif': true,
        'konuSayisi': 0,
        'mesajSayisi': 0,
        'olusturmaTarihi': FieldValue.serverTimestamp(),
      },
      {
        'id': 'transferler',
        'ad': 'Transfer & Kadro',
        'aciklama': 'Transfer haberleri ve kadro değişiklikleri',
        'ikon': 'swap_horiz',
        'renk': 0xFFFF9800,
        'sira': 3,
        'aktif': true,
        'konuSayisi': 0,
        'mesajSayisi': 0,
        'olusturmaTarihi': FieldValue.serverTimestamp(),
      },
      {
        'id': 'diger',
        'ad': 'Diğer Konular',
        'aciklama': 'Futbol dışı konular',
        'ikon': 'more_horiz',
        'renk': 0xFF607D8B,
        'sira': 4,
        'aktif': true,
        'konuSayisi': 0,
        'mesajSayisi': 0,
        'olusturmaTarihi': FieldValue.serverTimestamp(),
      },
    ];

    for (var category in categories) {
      final docRef = firestore.collection('forum_kategorileri').doc(category['id'] as String);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set(category);
      }
    }
  }

  int _safeIntValue(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  String _safeStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Forum',
      ),
      body: !_isInitialized
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      )
          : _buildForumContent(),
    );
  }

  Widget _buildForumContent() {
    return Column(
      children: [
        _buildForumHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('forum_kategorileri')
                .where('aktif', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Kategoriler yüklenirken hata oluştu'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Henüz kategori yok',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              var docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;

                final aSira = _safeIntValue(aData['sira'], 99);
                final bSira = _safeIntValue(bData['sira'], 99);

                return aSira.compareTo(bSira);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildCategoryCard(data, docs[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.8),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Kocaelispor Forum',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Takımımız hakkında konuşalım!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> data, String id) {
    final ad = _safeStringValue(data['ad'], 'Kategori');
    final aciklama = _safeStringValue(data['aciklama'], '');
    final ikonAdi = _safeStringValue(data['ikon'], 'chat');
    final renkDegeri = _safeIntValue(data['renk'], 0xFF4CAF50);
    final konuSayisi = _safeIntValue(data['konuSayisi'], 0);
    final mesajSayisi = _safeIntValue(data['mesajSayisi'], 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _goToCategory(data, id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(renkDegeri).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(ikonAdi),
                    color: Color(renkDegeri),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aciklama,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatItem(
                            Icons.topic_outlined,
                            '$konuSayisi Konu',
                            Color(renkDegeri),
                          ),
                          const SizedBox(width: 16),
                          _buildStatItem(
                            Icons.message_outlined,
                            '$mesajSayisi Mesaj',
                            Colors.grey[600]!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'chat':
        return Icons.chat;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'history_edu':
        return Icons.history_edu;
      default:
        return Icons.forum;
    }
  }

  void _goToCategory(Map<String, dynamic> data, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KategoriDetaySayfasi(
          kategoriAd: data['ad'] ?? 'Kategori',
          kategoriId: id,
          kategoriRenk: Color(_safeIntValue(data['renk'], 0xFF4CAF50)),
          kategoriIkon: _getIconData(_safeStringValue(data['ikon'], 'chat')),
        ),
      ),
    );
  }
}

// KATEGORİ DETAY SAYFASI
class KategoriDetaySayfasi extends StatelessWidget {
  final String kategoriAd;
  final String kategoriId;
  final Color kategoriRenk;
  final IconData kategoriIkon;

  const KategoriDetaySayfasi({
    super.key,
    required this.kategoriAd,
    required this.kategoriId,
    required this.kategoriRenk,
    required this.kategoriIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kategoriAd),
        backgroundColor: kategoriRenk,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _yeniKonuOlustur(context),
        backgroundColor: kategoriRenk,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Konu'),
      ),
      body: Column(
        children: [
          _buildKategoriBilgi(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_konulari')
                  .where('kategoriId', isEqualTo: kategoriId)
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Geri Dön'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyWidget(context);
                }

                final konular = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: konular.length,
                  itemBuilder: (context, index) {
                    final data = konular[index].data() as Map<String, dynamic>;
                    return _buildKonuCard(context, data, konular[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriBilgi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kategoriRenk.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: kategoriRenk.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            kategoriIkon,
            color: kategoriRenk,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kategoriAd,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kategoriRenk,
                ),
              ),
              Text(
                'Konuları görüntüleyin ve yeni konu açın',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_outlined,
            size: 80,
            color: kategoriRenk.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Henüz konu yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk konuyu sen aç!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _yeniKonuOlustur(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kategoriRenk,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('İlk Konuyu Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildKonuCard(BuildContext context, Map<String, dynamic> data, String konuId) {
    final baslik = data['baslik'] ?? 'Başlıksız Konu';
    final olusturanAd = data['olusturanAd'] ?? 'Anonim';
    final mesajSayisi = data['mesajSayisi'] ?? 0;
    final goruntulemeSayisi = data['goruntulemeSayisi'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _konuyaGit(context, data, konuId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      olusturanAd,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.message_outlined,
                      size: 14,
                      color: kategoriRenk,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$mesajSayisi mesaj',
                      style: TextStyle(
                        fontSize: 12,
                        color: kategoriRenk,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$goruntulemeSayisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _yeniKonuOlustur(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KonuOlusturSayfasi(
          kategoriAd: kategoriAd,
          kategoriId: kategoriId,
          kategoriRenk: kategoriRenk,
        ),
      ),
    );
  }

  void _konuyaGit(BuildContext context, Map<String, dynamic> data, String konuId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KonuDetaySayfasi(
          konuBaslik: data['baslik'] ?? 'Başlıksız Konu',
          konuId: konuId,
          kategoriRenk: kategoriRenk,
        ),
      ),
    );
  }
}

// KONU OLUŞTURMA SAYFASI
class KonuOlusturSayfasi extends StatefulWidget {
  final String kategoriAd;
  final String kategoriId;
  final Color kategoriRenk;

  const KonuOlusturSayfasi({
    super.key,
    required this.kategoriAd,
    required this.kategoriId,
    required this.kategoriRenk,
  });

  @override
  State<KonuOlusturSayfasi> createState() => _KonuOlusturSayfasiState();
}

class _KonuOlusturSayfasiState extends State<KonuOlusturSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _mesajController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _mesajController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Konu - ${widget.kategoriAd}'),
        backgroundColor: widget.kategoriRenk,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _baslikController,
              decoration: const InputDecoration(
                labelText: 'Konu Başlığı',
                hintText: 'Konunuzun başlığını yazın...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık boş olamaz';
                }
                if (value.trim().length < 5) {
                  return 'Başlık en az 5 karakter olmalı';
                }
                return null;
              },
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _aciklamaController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (İsteğe bağlı)',
                hintText: 'Konu hakkında kısa bir açıklama...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              maxLength: 200,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _mesajController,
              decoration: const InputDecoration(
                labelText: 'İlk Mesaj',
                hintText: 'Konunuzun ilk mesajını yazın...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'İlk mesaj boş olamaz';
                }
                if (value.trim().length < 10) {
                  return 'Mesaj en az 10 karakter olmalı';
                }
                return null;
              },
              maxLines: 5,
              maxLength: 1000,
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _konuOlustur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.kategoriRenk,
                  foregroundColor: Colors.white,
                ),
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(
                  _isLoading ? 'Oluşturuluyor...' : 'Konuyu Oluştur',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _konuOlustur() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Konu oluşturmak için giriş yapmalısınız', true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final konuRef = await FirebaseFirestore.instance.collection('forum_konulari').add({
        'baslik': _baslikController.text.trim(),
        'aciklama': _aciklamaController.text.trim().isEmpty
            ? null
            : _aciklamaController.text.trim(),
        'kategoriId': widget.kategoriId,
        'olusturanId': user.uid,
        'olusturanAd': user.displayName ?? 'Kocaelispor Taraftarı',
        'olusturanFoto': user.photoURL,
        'olusturmaTarihi': FieldValue.serverTimestamp(),
        'sabitlenmis': false,
        'kilitli': false,
        'mesajSayisi': 1,
        'goruntulemeSayisi': 0,
        'sonMesajTarihi': FieldValue.serverTimestamp(),
        'sonMesajGonderenAd': user.displayName ?? 'Kocaelispor Taraftarı',
      });

      await FirebaseFirestore.instance.collection('forum_mesajlari').add({
        'icerik': _mesajController.text.trim(),
        'konuId': konuRef.id,
        'gonderenId': user.uid,
        'gonderenAd': user.displayName ?? 'Kocaelispor Taraftarı',
        'gonderenFoto': user.photoURL,
        'tarih': FieldValue.serverTimestamp(),
        'duzenlendiMi': false,
      });

      _showSnackBar('Konu başarıyla oluşturuldu! ⚽', false);
      Navigator.pop(context);

    } catch (e) {
      print('Konu oluşturma hatası: $e');
      _showSnackBar('Konu oluşturulamadı!', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : widget.kategoriRenk,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}

// KONU DETAY SAYFASI
class KonuDetaySayfasi extends StatefulWidget {
  final String konuBaslik;
  final String konuId;
  final Color kategoriRenk;

  const KonuDetaySayfasi({
    super.key,
    required this.konuBaslik,
    required this.konuId,
    required this.kategoriRenk,
  });

  @override
  State<KonuDetaySayfasi> createState() => _KonuDetaySayfasiState();
}

class _KonuDetaySayfasiState extends State<KonuDetaySayfasi> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text(widget.konuBaslik),
    backgroundColor: widget.kategoriRenk,
    foregroundColor: Colors.white,
    ),
    body: Column(
    children: [
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance