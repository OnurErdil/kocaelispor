// lib/screens/foto_detay_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/foto_model.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class FotoDetaySayfasi extends StatefulWidget {
  final Foto foto;

  const FotoDetaySayfasi({super.key, required this.foto});

  @override
  State<FotoDetaySayfasi> createState() => _FotoDetaySayfasiState();
}

class _FotoDetaySayfasiState extends State<FotoDetaySayfasi> {
  late int _currentLikes;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.foto.begeniSayisi;
  }

  Future<void> _toggleLike() async {
    setState(() {
      if (_isLiked) {
        _currentLikes--;
        _isLiked = false;
      } else {
        _currentLikes++;
        _isLiked = true;
      }
    });

    try {
      await FirebaseFirestore.instance
          .collection('fotograflar')
          .doc(widget.foto.id)
          .update({'begeniSayisi': _currentLikes});
    } catch (e) {
      // Hata durumunda geri al
      setState(() {
        if (_isLiked) {
          _currentLikes--;
          _isLiked = false;
        } else {
          _currentLikes++;
          _isLiked = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Fotoğraf Detayı",
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ana fotoğraf
            Hero(
              tag: widget.foto.id,
              child: Container(
                width: double.infinity,
                height: 300,
                child: Image.network(
                  widget.foto.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
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
                  // Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Foto.getKategoriColor(widget.foto.kategori).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Foto.getKategoriIcon(widget.foto.kategori),
                          size: 18,
                          color: Foto.getKategoriColor(widget.foto.kategori),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.foto.kategori,
                          style: TextStyle(
                            fontSize: 14,
                            color: Foto.getKategoriColor(widget.foto.kategori),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Açıklama (varsa)
                  if (widget.foto.aciklama != null && widget.foto.aciklama!.isNotEmpty) ...[
                    const Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.foto.aciklama!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Etiketler (varsa)
                  if (widget.foto.etiketler.isNotEmpty) ...[
                    const Text(
                      'Etiketler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.foto.etiketler.map((etiket) {
                        return Chip(
                          label: Text(etiket),
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Kocaelispor footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Kocaelispor 1966 - Resmi Fotoğraf',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}: 16),

// Başlık
Text(
widget.foto.baslik,
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
height: 1.3,
),
),

const SizedBox(height: 16),

// Tarih ve fotoğrafçı bilgileri
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: AppTheme.primaryGreen.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
Icons.access_time,
size: 18,
color: AppTheme.primaryGreen,
),
const SizedBox(width: 6),
Text(
widget.foto.formattedDate,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w500,
),
),
if (widget.foto.fotografci != null) ...[
const SizedBox(width: 16),
Icon(
Icons.camera_alt,
size: 18,
color: AppTheme.primaryGreen,
),
const SizedBox(width: 6),
Text(
widget.foto.fotografci!,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w500,
),
),
],
],
),
),

const SizedBox(height: 24),

// Beğeni butonu
Row(
children: [
ElevatedButton.icon(
onPressed: _toggleLike,
icon: Icon(
_isLiked ? Icons.favorite : Icons.favorite_border,
color: _isLiked ? Colors.red : Colors.grey,
),
label: Text('$_currentLikes'),
style: ElevatedButton.styleFrom(
backgroundColor: _isLiked
? Colors.red.withOpacity(0.1)
    : Colors.grey.withOpacity(0.1),
foregroundColor: _isLiked ? Colors.red : Colors.grey,
elevation: 0,
),
),
const SizedBox(width: 16),
ElevatedButton.icon(
onPressed: () {
// Paylaş özelliği
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Fotoğraf paylaşıldı!'),
backgroundColor: AppTheme.primaryGreen,
),
);
},
icon: const Icon(Icons.share),
label: const Text('Paylaş'),
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
foregroundColor: AppTheme.primaryGreen,
elevation: 0,
),
),
],
),

const SizedBox(height