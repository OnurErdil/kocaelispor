// lib/screens/puan_durumu_ekle_sayfasi.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PuanDurumuEkleSayfasi extends StatefulWidget {
  const PuanDurumuEkleSayfasi({super.key});

  @override
  State<PuanDurumuEkleSayfasi> createState() => _PuanEkleSayfasiState();
}

class _PuanEkleSayfasiState extends State<PuanDurumuEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _takimController = TextEditingController();
  final TextEditingController _siraController = TextEditingController();
  final TextEditingController _oController = TextEditingController();
  final TextEditingController _gController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  final TextEditingController _mController = TextEditingController();
  final TextEditingController _puanController = TextEditingController();
  final TextEditingController _avController = TextEditingController();

  static const Color _primaryColor = Color(0xFF00913C);

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection("puan_durumu").add({
        "takim": _takimController.text.trim(),
        "sira": int.parse(_siraController.text),
        "o": int.parse(_oController.text),
        "g": int.parse(_gController.text),
        "b": int.parse(_bController.text),
        "m": int.parse(_mController.text),
        "puan": int.parse(_puanController.text),
        "av": _avController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puan durumu eklendi!'),
          backgroundColor: _primaryColor,
        ),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _takimController.dispose();
    _siraController.dispose();
    _oController.dispose();
    _gController.dispose();
    _bController.dispose();
    _mController.dispose();
    _puanController.dispose();
    _avController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Puan Girişi"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_takimController, "Takım Adı"),
              _buildTextField(_siraController, "Sıra", isNumber: true),
              _buildTextField(_oController, "Oynadığı Maç", isNumber: true),
              _buildTextField(_gController, "Galibiyet", isNumber: true),
              _buildTextField(_bController, "Beraberlik", isNumber: true),
              _buildTextField(_mController, "Mağlubiyet", isNumber: true),
              _buildTextField(_puanController, "Puan", isNumber: true),
              _buildTextField(_avController, "Averaj"),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _kaydet,
                icon: const Icon(Icons.save),
                label: const Text("Kaydet"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) => value == null || value.isEmpty
            ? "$label boş bırakılamaz"
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
