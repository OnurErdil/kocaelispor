import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart'; // ✅ Import ekleyin

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool isLoading = false;
  bool emailSent = false;

  void resetPassword() async {
    // E-posta alanı boş kontrolü
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-posta adresi gereklidir!")),
      );
      return;
    }

    // E-posta format kontrolü
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir e-posta adresi giriniz!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await auth.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      if (mounted) {
        setState(() => emailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Şifre sıfırlama maili gönderildi! E-postanızı kontrol ediniz."),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi.';
          break;
        case 'too-many-requests':
          errorMessage = 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyiniz.';
          break;
        default:
          errorMessage = 'Şifre sıfırlama maili gönderilirken hata oluştu: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Beklenmeyen hata: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Şifre Sıfırla",
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Şifrenizi mi Unuttunuz?",
                style: TextStyle(
                  fontSize: 28,
                  color: Color(0xFF00913C),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "E-posta adresinizi girin, size şifre sıfırlama linki gönderelim.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // E-posta alanı
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !emailSent,
                decoration: InputDecoration(
                  labelText: "E-posta",
                  labelStyle: const TextStyle(color: Color(0xFF00913C)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF00913C)),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF00913C)),
                  helperText: "Kayıtlı e-posta adresinizi giriniz",
                ),
              ),
              const SizedBox(height: 24),

              // Başarı mesajı (e-posta gönderildiyse)
              if (emailSent) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "E-posta Gönderildi!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Spam klasörünüzü de kontrol etmeyi unutmayın.",
                              style: TextStyle(color: Colors.green.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Sıfırlama maili gönder butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading || emailSent ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00913C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    emailSent ? "E-posta Gönderildi" : "Sıfırlama Maili Gönder",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // E-posta tekrar gönder butonu (e-posta gönderildiyse)
              if (emailSent) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () {
                      setState(() => emailSent = false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00913C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Tekrar Gönder",
                      style: TextStyle(color: Color(0xFF00913C), fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Giriş sayfasına dön linki
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Şifrenizi hatırladınız mı? "),
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text(
                      "Giriş Yap",
                      style: TextStyle(color: Color(0xFF00913C)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}