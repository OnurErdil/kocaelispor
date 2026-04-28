import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/google_signin_service.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import 'admin_panel_screen.dart';
import 'settings_page.dart'; // ✅ YENİ IMPORT
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  User? get user => FirebaseAuth.instance.currentUser;

  bool isLoading = false;
  bool isAdmin = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> refreshUserStatus({bool showMessage = true}) async {
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      await _checkAdminStatus();

      if (mounted) {
        setState(() {});

        if (showMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    user?.emailVerified == true
                        ? Icons.verified
                        : Icons.info_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user?.emailVerified == true
                          ? "E-posta doğrulaması onaylandı!"
                          : "E-posta henüz doğrulanmamış görünüyor.",
                    ),
                  ),
                ],
              ),
              backgroundColor: user?.emailVerified == true
                  ? Colors.green.shade600
                  : Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Doğrulama durumu yenilenemedi: ${e.toString()}"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final adminStatus = await AdminService.isCurrentUserAdmin();
      setState(() {
        isAdmin = adminStatus;
      });
    } catch (e) {
      setState(() {
        isAdmin = false;
      });
    }
  }

  Future<void> signOut() async {
    HapticFeedback.mediumImpact();

    bool? shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Çıkış Yap",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            "Hesabınızdan çıkmak istediğinizden emin misiniz?",
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "İptal",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Çıkış Yap"),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignInService.signOutGoogle();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Çıkış yapılırken hata oluştu: ${e.toString()}"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> sendEmailVerification() async {
    if (user == null || user!.emailVerified) return;

    setState(() => isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await user!.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Doğrulama e-postası gönderildi. Maili onayladıktan sonra durumu yenileyin.",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("E-posta gönderilemedi: ${e.toString()}"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _openAdminPanel() async {
    HapticFeedback.lightImpact();

    // Admin paneli erişim kontrolü
    final canAccess = await AdminService.canAccessAdminPanel();
    if (!canAccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Admin paneline erişim yetkiniz yok!"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
      );
    }
  }

  String getProviderInfo() {
    if (user?.providerData.isNotEmpty == true) {
      final providerId = user!.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          return 'Google ile giriş';
        case 'password':
          return 'E-posta ile giriş';
        default:
          return 'Bilinmeyen giriş';
      }
    }
    return 'Giriş bilgisi yok';
  }

  IconData getProviderIcon() {
    if (user?.providerData.isNotEmpty == true) {
      final providerId = user!.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          return Icons.account_circle;
        case 'password':
          return Icons.email;
        default:
          return Icons.login;
      }
    }
    return Icons.help_outline;
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: user == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Kullanıcı bulunamadı!",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen,
              AppTheme.primaryDark,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await refreshUserStatus(showMessage: false);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header with profile photo
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(_slideAnimation),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile photo with animated border
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: user!.photoURL != null
                                      ? NetworkImage(user!.photoURL!)
                                      : null,
                                  child: user!.photoURL == null
                                      ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.primaryGreen,
                                  )
                                      : null,
                                ),
                              ),
                              // Admin badge
                              if (isAdmin)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.admin_panel_settings,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // User name
                          Text(
                            user!.displayName ?? 'Kocaelispor Fan',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          // Admin badge text
                          if (isAdmin)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Email verification status
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user!.emailVerified
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user!.emailVerified
                                      ? Icons.verified
                                      : Icons.warning,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user!.emailVerified
                                      ? 'Doğrulanmış'
                                      : 'Doğrulanmamış',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content cards
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Account info cards
                          ..._buildInfoCards(),

                          const SizedBox(height: 24),

                          // Ayarlar butonu
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              ),
                              icon: const Icon(Icons.settings),
                              label: const Text("Ayarlar"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Admin panel button
                          if (isAdmin) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _openAdminPanel,
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text("Admin Paneli"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Email verification buttons
                          if (!user!.emailVerified) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade400,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange.shade900,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "E-posta adresiniz henüz doğrulanmamış. Mail kutunuzu kontrol edin.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade900,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : sendEmailVerification,
                                icon: const Icon(Icons.mark_email_read),
                                label: const Text("Doğrulama Maili Gönder"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => refreshUserStatus(showMessage: true),
                                icon: const Icon(Icons.refresh),
                                label: const Text("Doğrulama Durumunu Yenile"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange.shade700,
                                  side: BorderSide(color: Colors.orange.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Sign out button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : signOut,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(Icons.logout_rounded),
                              label: Text(
                                isLoading ? "Çıkış yapılıyor..." : "Çıkış Yap",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Kocaelispor footer
                          Container(
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
                                  "Kocaelispor'a Hoş Geldiniz",
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInfoCards() {
    return [
      _InfoCard(
        icon: Icons.email_outlined,
        title: "E-posta",
        value: user!.email ?? 'E-posta yok',
        trailing: Icon(
          user!.emailVerified ? Icons.verified : Icons.warning,
          color: user!.emailVerified ? Colors.green : Colors.orange,
        ),
      ),
      const SizedBox(height: 12),
      _InfoCard(
        icon: getProviderIcon(),
        title: "Giriş Yöntemi",
        value: getProviderInfo(),
      ),
      const SizedBox(height: 12),
      if (isAdmin)
        _InfoCard(
          icon: Icons.admin_panel_settings,
          title: "Yetki",
          value: "Yönetici",
          trailing: Icon(
            Icons.admin_panel_settings,
            color: Colors.orange.shade600,
          ),
        ),
      if (isAdmin) const SizedBox(height: 12),
      _InfoCard(
        icon: Icons.calendar_today_outlined,
        title: "Üyelik Tarihi",
        value: formatDate(user!.metadata.creationTime),
      ),
      const SizedBox(height: 12),
      _InfoCard(
        icon: Icons.access_time,
        title: "Son Giriş",
        value: formatDate(user!.metadata.lastSignInTime),
      ),
    ];
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}