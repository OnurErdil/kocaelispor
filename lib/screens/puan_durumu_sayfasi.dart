// lib/screens/puan_durumu_sayfasi.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'puan_durumu_ekle_sayfasi.dart';

// Constants
class AppConstants {
  static const Color primaryColor = Color(0xFF00913C);
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color successColor = Colors.green;
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121);
  static const Color subtitleColor = Color(0xFF757575);

  // Responsive breakpoints
  static const double compactWidth = 400;
  static const double tabletWidth = 768;

  // Required JSON fields
  static const List<String> requiredFields = [
    'takim', 'sira', 'o', 'g', 'b', 'm', 'puan', 'av'
  ];
}

class PuanDurumuSayfasi extends StatefulWidget {
  const PuanDurumuSayfasi({super.key});

  @override
  State<PuanDurumuSayfasi> createState() => _PuanDurumuSayfasiState();
}

class _PuanDurumuSayfasiState extends State<PuanDurumuSayfasi> {
  bool _isCheckingAdmin = true;
  bool _isAdmin = false;
  String? _errorMessage;

  // Optimize: Move query outside build method
  late final Query<Map<String, dynamic>> _puanDurumuQuery;

  @override
  void initState() {
    super.initState();
    _puanDurumuQuery = FirebaseFirestore.instance
        .collection("puan_durumu")
        .orderBy('sira');
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isCheckingAdmin = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      setState(() {
        _isAdmin = userData?['role'] == 'admin';
        _isCheckingAdmin = false;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
        _errorMessage = 'Kullanıcı bilgileri kontrol edilemedi: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _errorMessage = null);
    await _checkAdminStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("Puan Durumu"),
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        if (_errorMessage != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Yenile',
          ),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!_isAdmin || _isCheckingAdmin) return null;

    return FloatingActionButton(
      backgroundColor: AppConstants.primaryColor,
      child: const Icon(Icons.edit, color: Colors.white),
      onPressed: () async {
        HapticFeedback.lightImpact();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PuanDurumuEkleSayfasi(),
          ),
        );
        if (result == true) {
          _refreshData();
        }
      },
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppConstants.primaryColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: _puanDurumuQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(
              'Veriler yüklenirken hata oluştu: ${snapshot.error}',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyWidget();
          }

          final takimlar = snapshot.data!.docs;
          return _buildTakimList(takimlar);
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          SizedBox(height: 16),
          Text('Puan durumu yükleniyor...',
              style: TextStyle(color: AppConstants.textColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Henüz puan durumu eklenmemiş',
            style: TextStyle(fontSize: 16, color: AppConstants.subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTakimList(List<QueryDocumentSnapshot> takimlar) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: takimlar.length,
      itemBuilder: (context, index) {
        final data = takimlar[index].data() as Map<String, dynamic>;
        return _buildTakimCard(data, index);
      },
    );
  }

  Widget _buildTakimCard(Map<String, dynamic> data, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < AppConstants.compactWidth;
        return _buildResponsiveCard(data, index, isCompact);
      },
    );
  }

  Widget _buildResponsiveCard(Map<String, dynamic> data, int index, bool isCompact) {
    // Veri validasyonu ve null safety
    final sira = _safeString(data['sira'], '?');
    final takim = _safeString(data['takim'], 'Bilinmeyen Takım');
    final o = _safeString(data['o'], '0');
    final g = _safeString(data['g'], '0');
    final b = _safeString(data['b'], '0');
    final m = _safeString(data['m'], '0');
    final puan = _safeString(data['puan'], '0');
    final av = _safeString(data['av'], '0');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 2,
      color: AppConstants.cardColor,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Semantics(
          label: 'Takım sıralaması $sira, $takim',
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPuanRengi(int.tryParse(puan) ?? 0),
              child: Text(
                sira,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              takim,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: isCompact
                ? Text(
              "O:$o G:$g B:$b M:$m P:$puan",
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.subtitleColor,
              ),
            )
                : Text(
              "Oynanan: $o | Galibiyet: $g | Beraberlik: $b | Mağlubiyet: $m | Puan: $puan",
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.subtitleColor,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "AV: $av",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  Color _getPuanRengi(int puan) {
    if (puan >= 40) return AppConstants.successColor;
    if (puan >= 20) return AppConstants.warningColor;
    return AppConstants.errorColor;
  }

  Widget _buildErrorWidget([String? customError]) {
    final errorText = customError ?? _errorMessage ?? 'Bilinmeyen hata';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppConstants.errorColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _refreshData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class JsonGuncelleDialog extends StatefulWidget {
  const JsonGuncelleDialog({super.key});

  @override
  State<JsonGuncelleDialog> createState() => _JsonGuncelleDialogState();
}

class _JsonGuncelleDialogState extends State<JsonGuncelleDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<dynamic>? _validateJson(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);

      if (decoded is! List) {
        throw const FormatException('JSON bir liste olmalıdır');
      }

      for (int i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map<String, dynamic>) {
          throw FormatException('${i + 1}. öğe bir nesne olmalıdır');
        }

        // Zorunlu alanları kontrol et
        for (final field in AppConstants.requiredFields) {
          if (!item.containsKey(field)) {
            throw FormatException('${i + 1}. öğede "$field" alanı eksik');
          }
        }

        // Sayısal alanları kontrol et
        final numericFields = ['sira', 'o', 'g', 'b', 'm', 'puan'];
        for (final field in numericFields) {
          final value = item[field];
          if (value is! num && num.tryParse(value.toString()) == null) {
            throw FormatException('${i + 1}. öğede "$field" sayı olmalıdır');
          }
        }
      }

      return decoded;
    } catch (e) {
      // FIX: Set validation error to state
      setState(() => _validationError = e.toString());
      return null;
    }
  }

  void _onJsonChanged(String value) {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
  }

  Future<void> _guncelle() async {
    final jsonText = _controller.text.trim();

    if (jsonText.isEmpty) {
      setState(() => _validationError = 'JSON verisi boş olamaz');
      return;
    }

    final validatedData = _validateJson(jsonText);
    if (validatedData == null) {
      return; // Hata mesajı zaten _validateJson içinde set edildi
    }

    setState(() {
      _isLoading = true;
      _validationError = null;
    });

    try {
      final puanRef = FirebaseFirestore.instance.collection("puan_durumu");
      final batch = FirebaseFirestore.instance.batch();

      // Mevcut verileri sil
      final snapshot = await puanRef.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Yeni verileri ekle
      for (final takim in validatedData) {
        batch.set(puanRef.doc(), takim);
      }

      await batch.commit();

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Puan durumu başarıyla güncellendi!"),
              ],
            ),
            backgroundColor: AppConstants.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _validationError = 'Güncelleme hatası: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Puan Durumu JSON Güncelle"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerekli alanlar: ${AppConstants.requiredFields.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              onChanged: _onJsonChanged,
              maxLines: 15,
              decoration: InputDecoration(
                hintText: '''[
  {
    "takim": "Galatasaray",
    "sira": 1,
    "o": 10,
    "g": 8,
    "b": 2,
    "m": 0,
    "puan": 26,
    "av": "+12"
  }
]''',
                border: const OutlineInputBorder(),
                errorText: _validationError,
                errorMaxLines: 3,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _guncelle,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text("Kaydet"),
        ),
      ],
    );
  }
}