// lib/screens/takvim_sayfasi.dart - TAM EKSİKSİZ KOD
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'puan_durumu_sayfasi.dart';
import 'all_fixtures_page.dart';

class TakvimSayfasi extends StatefulWidget {
  const TakvimSayfasi({super.key});

  @override
  State<TakvimSayfasi> createState() => _TakvimSayfasiState();
}

class _TakvimSayfasiState extends State<TakvimSayfasi> with TickerProviderStateMixin {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();
        setState(() {
          _isAdmin = adminDoc.exists;
          _isCheckingAdmin = false;
        });
      } else {
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
      }
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
      appBar: AppBar(
        title: const Text('Takvim'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0F0F), Color(0xFF2D2D2D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      floatingActionButton: _isAdmin ? _buildFAB() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            if (_isCheckingAdmin) _buildLoadingBar(),
            if (!_isCheckingAdmin && _isAdmin) _buildAdminBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('SON MAÇ:', Icons.sports_soccer),
                      const SizedBox(height: 16),
                      _buildLastMatch(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('SIRADAKİ MAÇ:', Icons.schedule),
                      const SizedBox(height: 16),
                      _buildNextMatch(),
                      const SizedBox(height: 32),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade800,
      child: const Center(
        child: Text('Yetki kontrolü yapılıyor...', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildAdminBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppTheme.primaryGreen.withOpacity(0.2),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          const Text(
            'Admin modunda - Maç ekleyebilir ve düzenleyebilirsiniz',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLastMatch() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .orderBy('tarih', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorCard('Son maç yüklenemedi');
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingCard();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('Henüz oynanmış maç bulunmuyor');
        }

        final finishedMatches = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final skor = data['skor'];
          if (skor == null) return false;
          if (skor is Map) {
            final evSahibiSkor = skor['ev_sahibi'] ?? skor['evSahibi'];
            final deplasmanSkor = skor['deplasman'] ?? skor['rakip'];
            return evSahibiSkor != null && deplasmanSkor != null;
          }
          if (skor is String) return skor.isNotEmpty && skor.contains('-');
          return false;
        }).toList();

        if (finishedMatches.isEmpty) return _buildEmptyCard('Henüz oynanmış maç bulunmuyor');
        return _buildMatchCard(finishedMatches.first, isLastMatch: true);
      },
    );
  }

  Widget _buildNextMatch() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .where('tarih', isGreaterThan: Timestamp.now())
          .orderBy('tarih', descending: false)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorCard('Sıradaki maç yüklenemedi');
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingCard();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('Yaklaşan maç bulunmuyor');
        }
        return _buildMatchCard(snapshot.data!.docs.first, isNextMatch: true);
      },
    );
  }

  Widget _buildMatchCard(DocumentSnapshot doc, {bool isLastMatch = false, bool isNextMatch = false}) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['tarih'] as Timestamp?;
    final homeTeam = data['ev_sahibi'] ?? data['evSahibi'] ?? 'Kocaelispor';
    final awayTeam = data['deplasman'] ?? data['rakip'] ?? 'Rakip';
    final homeLogoUrl = data['ev_sahibi_logo'] ?? data['evSahibiLogo'];
    final awayLogoUrl = data['deplasman_logo'] ?? data['rakipLogo'];
    final stad = data['stad'] ?? data['lokasyon'] ?? 'Stadyum';

    final skorData = data['skor'];
    dynamic homeScore, awayScore;
    if (skorData is Map) {
      homeScore = skorData['ev_sahibi'] ?? skorData['evSahibi'];
      awayScore = skorData['deplasman'] ?? skorData['rakip'];
    } else if (skorData is String && skorData.contains('-')) {
      final parts = skorData.split('-');
      if (parts.length == 2) {
        homeScore = parts[0].trim();
        awayScore = parts[1].trim();
      }
    }

    final matchDate = timestamp?.toDate() ?? DateTime.now();
    final isFinished = homeScore != null && awayScore != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLastMatch ? Colors.green.withOpacity(0.5)
              : isNextMatch ? Colors.orange.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(homeLogoUrl, homeTeam),
                    const SizedBox(height: 8),
                    Text(homeTeam, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text('$homeScore - $awayScore', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    const SizedBox(height: 8),
                    Text('${matchDate.day}/${matchDate.month}/${matchDate.year}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(awayLogoUrl, awayTeam),
                    const SizedBox(height: 8),
                    Text(awayTeam, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
          if (stad.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(stad, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
          if (_isAdmin && !isFinished) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showScoreDialog(doc.id, homeTeam, awayTeam),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
              child: const Text('Skor Gir'),
            ),
          ],
          if (isNextMatch && !isFinished) ...[
            const SizedBox(height: 12),
            _CountdownWidget(matchDate: matchDate),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl, String teamName) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade600)),
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(logoUrl, width: 60, height: 60, fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          errorBuilder: (context, error, stackTrace) => Icon(Icons.sports_soccer, color: Colors.grey.shade400, size: 30),
        ),
      )
          : Icon(Icons.sports_soccer, color: Colors.grey.shade400, size: 30),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12)),
      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.5))),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 16))),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16))),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllFixturesPage())),
                  icon: const Icon(Icons.list, color: Colors.white),
                  label: const Text('Tüm Fikstür', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PuanDurumuSayfasi())),
                  icon: const Icon(Icons.leaderboard, color: Colors.white),
                  label: const Text('Puan Durumu', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddMatchDialog,
      backgroundColor: AppTheme.primaryGreen,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showScoreDialog(String docId, String homeTeam, String awayTeam) {
    final homeController = TextEditingController();
    final awayController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Maç Sonucu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$homeTeam - $awayTeam', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: homeController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: homeTeam, labelStyle: const TextStyle(color: Colors.grey), border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGreen))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: awayController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: awayTeam, labelStyle: const TextStyle(color: Colors.grey), border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGreen))),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final homeScore = homeController.text.trim();
              final awayScore = awayController.text.trim();
              if (homeScore.isNotEmpty && awayScore.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance.collection('maclar').doc(docId).update({
                    'skor': {'ev_sahibi': int.parse(homeScore), 'deplasman': int.parse(awayScore)}
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maç sonucu kaydedildi!'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMatchDialog() {
    final homeTeamController = TextEditingController();
    final awayTeamController = TextEditingController();
    final stadController = TextEditingController();
    final homeLogoController = TextEditingController();
    final awayLogoController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text('Yeni Maç Ekle', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: homeTeamController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ev Sahibi Takım',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: awayTeamController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Deplasman Takım',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stadController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Stadyum',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: homeLogoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Ev Sahibi Logo URL',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: awayLogoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Deplasman Logo URL',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryGreen)),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Maç Tarihi', style: TextStyle(color: Colors.white)),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.calendar_today, color: Colors.white),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: AppTheme.primaryGreen, surface: const Color(0xFF2D2D2D))), child: child!),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),
                ListTile(
                  title: const Text('Maç Saati', style: TextStyle(color: Colors.white)),
                  subtitle: Text('${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.access_time, color: Colors.white),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context, initialTime: selectedTime,
                      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: AppTheme.primaryGreen, surface: const Color(0xFF2D2D2D))), child: child!),
                    );
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                final homeTeam = homeTeamController.text.trim();
                final awayTeam = awayTeamController.text.trim();
                final stad = stadController.text.trim();
                final homeLogo = homeLogoController.text.trim();
                final awayLogo = awayLogoController.text.trim();

                if (homeTeam.isNotEmpty && awayTeam.isNotEmpty) {
                  try {
                    final matchDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                    await FirebaseFirestore.instance.collection('maclar').add({
                      'ev_sahibi': homeTeam, 'deplasman': awayTeam, 'stad': stad.isNotEmpty ? stad : 'Belirtilmemiş',
                      'ev_sahibi_logo': homeLogo, 'deplasman_logo': awayLogo, 'tarih': Timestamp.fromDate(matchDateTime),
                      'skor': null, 'olusturma_tarihi': Timestamp.now(),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maç başarıyla eklendi!'), backgroundColor: Colors.green));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen takım isimlerini girin!'), backgroundColor: Colors.orange));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Geri sayım widget'ı
class _CountdownWidget extends StatefulWidget {
  final DateTime matchDate;
  const _CountdownWidget({required this.matchDate});
  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _calculateTimeRemaining());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final difference = widget.matchDate.difference(DateTime.now());
    if (mounted) setState(() => _timeRemaining = difference.isNegative ? Duration.zero : difference);
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: const Text('Maç başladı!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      );
    }

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours.remainder(24);
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeUnit(days.toString(), 'Gün'),
          _buildTimeUnit(hours.toString().padLeft(2, '0'), 'Saat'),
          _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'Dakika'),
          _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'Saniye'),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}