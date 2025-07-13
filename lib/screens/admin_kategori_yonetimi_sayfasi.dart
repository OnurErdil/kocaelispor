// lib/screens/admin_kategori_yonetimi_sayfasi.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../models/forum_models.dart';
import '../services/forum_service.dart';

class AdminKategoriYonetimiSayfasi extends StatefulWidget {
  const AdminKategoriYonetimiSayfasi({super.key});

  @override
  State<AdminKategoriYonetimiSayfasi> createState() => _AdminKategoriYonetimiSayfasiState();
}

class _AdminKategoriYonetimiSayfasiState extends State<AdminKategoriYonetimiSayfasi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Kategori Yönetimi",
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _yeniKategoriDialog(),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kategori'),
      ),
      body: StreamBuilder<List<ForumKategori>>(
        stream: ForumService.getKategoriler(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorWidget('Kategoriler yüklenirken hata oluştu');
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget();
          }

          final kategoriler = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kategoriler.length,
            itemBuilder: (context, index) {
              final kategori = kategoriler[index];
              return _buildKategoriCard(kategori);
            },
          );
        },
      ),
    );
  }

  Widget _buildKategoriCard(ForumKategori kategori) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - başlık ve menu
              Row(
                children: [
                  // Kategori ikonu
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kategori.renk.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      kategori.ikon,
                      color: kategori.renk,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Kategori adı ve sıra
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              kategori.ad,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Sıra: ${kategori.sira}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kategori.aciklama,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Durum ve işlemler
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, kategori),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(
                              kategori.aktif ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(kategori.aktif ? 'Gizle' : 'Göster'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // İstatistikler ve durum
              Row(
                children: [
                  _buildStatChip(
                    Icons.topic,
                    '${kategori.konuSayisi} konu',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.message,
                    '${kategori.mesajSayisi} mesaj',
                    Colors.green,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kategori.aktif
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      kategori.aktif ? 'Aktif' : 'Pasif',
                      style: TextStyle(
                        fontSize: 12,
                        color: kategori.aktif ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              if (kategori.sonAktivite != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Son aktivite: ${_formatTarih(kategori.sonAktivite!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Henüz kategori yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'İlk kategoriyi oluşturun',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
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

  void _handleMenuAction(String action, ForumKategori kategori) {
    switch (action) {
      case 'edit':
        _kategoriDuzenleDialog(kategori);
        break;
      case 'toggle_status':
        _kategoriDurumDegistir(kategori);
        break;
      case 'delete':
        _kategoriSilDialog(kategori);
        break;
    }
  }

  // MARK: - Maç Konusu Oluşturma Fonksiyonu
  Future<void> _macKonusuOlustur() async {
    // Örnek maç verisi - gerçek uygulamada takvim servisinden gelecek
    await ForumService.macKonusuOlustur(
      macBasligi: "1. Hafta: Trabzonspor - Kocaelispor",
      macTarihi: DateTime.now().add(const Duration(days: 3)),
      evSahibi: "Trabzonspor",
      deplasman: "Kocaelispor",
      stadyum: "Şenol Güneş Stadyumu",
    );

    _showSnackBar('Maç konusu oluşturuldu! ⚽', false);
  }

  void _yeniKategoriDialog() {
    // Yeni kategori oluşturma dialog'u
    showDialog(
      context: context,
      builder: (context) => _KategoriEkleDialog(),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _kategoriDuzenleDialog(ForumKategori kategori) {
    // Kategori düzenleme dialog'u
    showDialog(
      context: context,
      builder: (context) => _KategoriEkleDialog(kategori: kategori),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  Future<void> _kategoriDurumDegistir(ForumKategori kategori) async {
    final success = await ForumService.kategoriGuncelle(
      kategori.id,
      {'aktif': !kategori.aktif},
    );

    if (success) {
      _showSnackBar(
        kategori.aktif ? 'Kategori gizlendi' : 'Kategori gösterildi',
        false,
      );
    } else {
      _showSnackBar('İşlem başarısız', true);
    }
  }

  void _kategoriSilDialog(ForumKategori kategori) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${kategori.ad} kategorisini silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Bu işlem geri alınamaz!\n\nKategoriye ait tüm konular ve mesajlar silinecek.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
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
            onPressed: () async {
              Navigator.pop(context);
              final success = await ForumService.kategoriSil(kategori.id);
              if (success) {
                _showSnackBar('Kategori silindi', false);
              } else {
                _showSnackBar('Kategori silinemedi', true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  String _formatTarih(DateTime tarih) {
    final now = DateTime.now();
    final difference = now.difference(tarih);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }
}

// MARK: - Kategori Ekleme/Düzenleme Dialog
class _KategoriEkleDialog extends StatefulWidget {
  final ForumKategori? kategori;

  const _KategoriEkleDialog({this.kategori});

  @override
  State<_KategoriEkleDialog> createState() => _KategoriEkleDialogState();
}

class _KategoriEkleDialogState extends State<_KategoriEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _siraController = TextEditingController();

  bool _isLoading = false;
  IconData _secilenIkon = Icons.forum;
  Color _secilenRenk = const Color(0xFF4CAF50);

  final List<IconData> _ikonlar = [
    Icons.forum,
    Icons.chat,
    Icons.sports_soccer,
    Icons.swap_horiz,
    Icons.history_edu,
    Icons.more_horiz,
    Icons.star,
    Icons.trending_up,
    Icons.group,
    Icons.announcement,
  ];

  final List<Color> _renkler = [
    const Color(0xFF4CAF50), // Yeşil
    const Color(0xFF2196F3), // Mavi
    const Color(0xFFFF9800), // Turuncu
    const Color(0xFF9C27B0), // Mor
    const Color(0xFFF44336), // Kırmızı
    const Color(0xFF607D8B), // Gri-Mavi
    const Color(0xFF795548), // Kahverengi
    const Color(0xFFE91E63), // Pembe
  ];

  @override
  void initState() {
    super.initState();
    if (widget.kategori != null) {
      _adController.text = widget.kategori!.ad;
      _aciklamaController.text = widget.kategori!.aciklama;
      _siraController.text = widget.kategori!.sira.toString();
      _secilenIkon = widget.kategori!.ikon;
      _secilenRenk = widget.kategori!.renk;
    }
  }

  @override
  void dispose() {
    _adController.dispose();
    _aciklamaController.dispose();
    _siraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.kategori != null;

    return AlertDialog(
      title: Text(isEdit ? 'Kategori Düzenle' : 'Yeni Kategori'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kategori adı
              TextFormField(
                controller: _adController,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kategori adı boş olamaz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _aciklamaController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Açıklama *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Açıklama boş olamaz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Sıra
              TextFormField(
                controller: _siraController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sıra Numarası *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sıra numarası boş olamaz';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // İkon seçimi
              const Text(
                'İkon Seçin:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ikonlar.map((ikon) {
                  final isSelected = _secilenIkon == ikon;
                  return GestureDetector(
                    onTap: () => setState(() => _secilenIkon = ikon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _secilenRenk.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _secilenRenk : Colors.grey,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        ikon,
                        color: isSelected ? _secilenRenk : Colors.grey,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Renk seçimi
              const Text(
                'Renk Seçin:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _renkler.map((renk) {
                  final isSelected = _secilenRenk == renk;
                  return GestureDetector(
                    onTap: () => setState(() => _secilenRenk = renk),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: renk,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Önizleme
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _secilenRenk.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _secilenRenk.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_secilenIkon, color: _secilenRenk, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _adController.text.isEmpty ? 'Kategori Adı' : _adController.text,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _secilenRenk,
                            ),
                          ),
                          Text(
                            _aciklamaController.text.isEmpty ? 'Açıklama' : _aciklamaController.text,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _kategoriKaydet,
          style: ElevatedButton.styleFrom(
            backgroundColor: _secilenRenk,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(isEdit ? 'Güncelle' : 'Oluştur'),
        ),
      ],
    );
  }

  Future<void> _kategoriKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final kategoriData = {
        'ad': _adController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
        'ikon': _secilenIkon.codePoint,
        'renk': _secilenRenk.value,
        'sira': int.parse(_siraController.text.trim()),
        'aktif': true,
      };

      bool success;
      if (widget.kategori != null) {
        // Güncelleme
        success = await ForumService.kategoriGuncelle(
          widget.kategori!.id,
          kategoriData,
        );
      } else {
        // Yeni oluşturma
        final yeniKategori = ForumKategori(
          id: _adController.text.trim().toLowerCase().replaceAll(' ', '_'),
          ad: _adController.text.trim(),
          aciklama: _aciklamaController.text.trim(),
          ikon: _secilenIkon,
          renk: _secilenRenk,
          sira: int.parse(_siraController.text.trim()),
          olusturmaTarihi: DateTime.now(),
        );

        success = await ForumService.kategoriEkle(yeniKategori);
      }

      if (mounted) {
        Navigator.pop(context, success);
      }
    } catch (e) {
      print('Kategori kaydetme hatası: $e');
      if (mounted) {
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}