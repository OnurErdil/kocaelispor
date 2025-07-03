// lib/screens/puan_durumu_form_ekrani.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PuanDurumuFormEkrani extends StatefulWidget {
  const PuanDurumuFormEkrani({super.key});

  @override
  State<PuanDurumuFormEkrani> createState() => _PuanDurumuFormEkraniState();
}

class _PuanDurumuFormEkraniState extends State<PuanDurumuFormEkrani> {
  static const Color _primaryColor = Color(0xFF00913C);
  List<Map<String, dynamic>> takimlar = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('puan_durumu')
        .orderBy('sira')
        .get();

    setState(() {
      takimlar = snapshot.docs.map((doc) => {...doc.data()}).toList();
    });
  }

  void _takimEkle() {
    setState(() {
      takimlar.add({
        "takim": "",
        "sira": takimlar.length + 1,
        "o": 0,
        "g": 0,
        "b": 0,
        "m": 0,
        "puan": 0,
        "av": "0",
      });
    });
  }

  void _takimSil(int index) {
    setState(() {
      takimlar.removeAt(index);
    });
  }

  Future<void> _kaydet() async {
    setState(() => _isLoading = true);

    final ref = FirebaseFirestore.instance.collection('puan_durumu');
    final batch = FirebaseFirestore.instance.batch();

    final snapshot = await ref.get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final takim in takimlar) {
      batch.set(ref.doc(), takim);
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Puan durumu güncellendi")),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildTakimForm(int index) {
    final takim = takimlar[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: takim["takim"],
                    decoration: const InputDecoration(labelText: "Takım"),
                    onChanged: (v) => takim["takim"] = v,
                  ),
                ),
                IconButton(
                  onPressed: () => _takimSil(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final field in ["sira", "o", "g", "b", "m", "puan"])
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: takim[field].toString(),
                      decoration: InputDecoration(labelText: field.toUpperCase()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => takim[field] = int.tryParse(v) ?? 0,
                    ),
                  ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: takim["av"].toString(),
                    decoration: const InputDecoration(labelText: "AV"),
                    onChanged: (v) => takim["av"] = v,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Puan Durumu Güncelle"),
        backgroundColor: _primaryColor,
        actions: [
          IconButton(
            onPressed: _takimEkle,
            icon: const Icon(Icons.add),
            tooltip: "Takım Ekle",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          itemCount: takimlar.length,
          itemBuilder: (context, index) =>
              _buildTakimForm(index),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _kaydet,
        label: const Text("Kaydet"),
        icon: const Icon(Icons.save),
        backgroundColor: _primaryColor,
      ),
    );
  }
}
