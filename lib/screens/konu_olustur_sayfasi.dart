// lib/screens/konu_olustur_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../models/forum_models.dart';
import '../services/forum_service.dart';

class KonuOlusturSayfasi extends StatefulWidget {
  final ForumKategori kategori;

  const KonuOlusturSayfasi({super.key, required this.kategori});

  @override
  State<KonuOlusturSayfasi> createState() => _KonuOlusturSayfasiState();
}

class _KonuOlusturSayfasiState extends State<KonuOlusturSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _ilkMesajController = TextEditingController();

  bool _isLoading = false;
  String? _secilenEtiket;

  final List<Map<String, dynamic>> _etiketler = [
    {'value': null, 'label': 'Etiket Yok', 'color': Colors.grey},
    {'value': 'hot', 'label': 'Popüler', 'color': Colors.red},
    {'value': 'new', 'label': 'Yeni', 'color': Colors.green},
    {'value': 'important', 'label': 'Önemli', 'color': Colors.orange},
  ];

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _ilkMesajController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Yeni Konu Oluştur",
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _konuOlustur,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'PAYLAŞ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kategori bilgisi
            _buildKategoriBilgi(),

            const SizedBox(height: 20),

            // Konu başlığı
            _buildBaslikField(),

            const SizedBox(height: 16),

            // Kısa açıklama
            _buildAciklamaField(),

            const SizedBox(height: 16),

            // Etiket seçimi
            _buildEtiketSecimi(),

            const SizedBox(height: 20),

            // İlk mesaj
            _buildIlkMesajField(),

            const SizedBox(height: 24),

            // Oluştur butonu
            _buildOlusturButonu(),

            const SizedBox(height: 16),

            // Kurallar hatırlatması
            _buildKurallarHatirlatmasi(),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriBilgi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.kategori.renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.kategori.renk.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.kategori.ikon,
            color: widget.kategori.renk,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kategori.ad,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.kategori.renk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.kategori.aciklama,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaslikField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konu Başlığı *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _baslikController,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Konunuzun çekici bir başlığını yazın...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.kategori.renk,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.title,
              color: widget.kategori.renk,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Konu başlığı boş olamaz';
            }
            if (value.trim().length < 5) {
              return 'Başlık en az 5 karakter olmalıdır';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAciklamaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kısa Açıklama',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _aciklamaController,
          maxLength: 200,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Konunuz hakkında kısa bir açıklama (opsiyonel)...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.kategori.renk,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.description,
              color: widget.kategori.renk,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEtiketSecimi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etiket',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _etiketler.map((etiket) {
            final isSelected = _secilenEtiket == etiket['value'];
            return FilterChip(
              selected: isSelected,
              label: Text(etiket['label']),
              onSelected: (selected) {
                setState(() {
                  _secilenEtiket = selected ? etiket['value'] : null;
                });
              },
              selectedColor: etiket['color'].withValues(alpha: 0.2),
              checkmarkColor: etiket['color'],
              side: BorderSide(
                color: isSelected
                    ? etiket['color']
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIlkMesajField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İlk Mesajınız *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ilkMesajController,
          maxLines: 8,
          maxLength: 1000,
          decoration: InputDecoration(
            hintText: 'Konunuz hakkında detaylı bilgi verin...\n\nÖrnek:\n- Neler düşünüyorsunuz?\n- Fikirlerinizi paylaşın\n- Sorunuzu sorun',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.kategori.renk,
                width: 2,
              ),
            ),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'İlk mesaj boş olamaz';
            }
            if (value.trim().length < 10) {
              return 'Mesaj en az 10 karakter olmalıdır';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOlusturButonu() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _konuOlustur,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.kategori.renk,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
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
    );
  }

  Widget _buildKurallarHatirlatmasi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Lütfen Dikkat!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Konu başlığınız açıklayıcı olsun\n'
                '• Saygılı bir dil kullanın\n'
                '• Kategoriye uygun konu açın\n'
                '• Aynı konuyu tekrar açmayın',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
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
      // Yeni konu oluştur
      final yeniKonu = ForumKonu(
        id: '', // Firestore otomatik oluşturacak
        baslik: _baslikController.text.trim(),
        aciklama: _aciklamaController.text.trim().isEmpty
            ? null
            : _aciklamaController.text.trim(),
        kategoriId: widget.kategori.id,
        olusturanId: user.uid,
        olusturanAd: user.displayName ?? 'Kocaelispor Taraftarı',
        olusturanFoto: user.photoURL,
        olusturmaTarihi: DateTime.now(),
        etiket: _secilenEtiket,
      );

      final konuId = await ForumService.konuEkle(yeniKonu);

      if (konuId != null) {
        // İlk mesajı ekle
        final ilkMesaj = ForumMesaj(
          id: '', // Firestore otomatik oluşturacak
          icerik: _ilkMesajController.text.trim(),
          konuId: konuId,
          gonderenId: user.uid,
          gonderenAd: user.displayName ?? 'Kocaelispor Taraftarı',
          gonderenFoto: user.photoURL,
          tarih: DateTime.now(),
        );

        await ForumService.mesajEkle(ilkMesaj);

        if (mounted) {
          _showSnackBar('Konu başarıyla oluşturuldu! 🎉', false);
          Navigator.pop(context);
        }
      } else {
        _showSnackBar('Konu oluşturulamadı. Lütfen tekrar deneyin.', true);
      }
    } catch (e) {
      print('Konu oluşturma hatası: $e');
      _showSnackBar('Bir hata oluştu. Lütfen tekrar deneyin.', true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
}