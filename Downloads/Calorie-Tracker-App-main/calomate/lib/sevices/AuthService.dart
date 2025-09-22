import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Thêm: Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      // Khởi động Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User hủy sign-in

      // Lấy authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in với Firebase
      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Thêm: Sign out Google nếu cần
    await _auth.signOut();
  }

  Stream<User?> get userChanges => _auth.userChanges();
}