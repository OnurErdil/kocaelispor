// lib/services/google_signin_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'admin_service.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Kullanıcı Google giriş penceresini kapattı veya iptal etti.
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        await AdminService.setupUserOnRegister(user);
        print("✅ Kullanıcı Firestore users koleksiyonu ile eşitlendi.");
      }

      return userCredential;
    } catch (e) {
      // Şimdilik hatayı uygulamayı çökertmeden yakalıyoruz.
      // Google OAuth ayarı eksikse burada origin_mismatch / ApiException gibi hata görülebilir.
      print("❌ Google Sign-In Hatası: $e");
      return null;
    }
  }

  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}