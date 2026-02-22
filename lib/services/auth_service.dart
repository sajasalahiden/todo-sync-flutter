import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e, isLogin: false));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e, isLogin: true));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapAuthError(FirebaseAuthException e, {required bool isLogin}) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      default:
        return isLogin ? 'Unable to log in right now.' : 'Unable to create account right now.';
    }
  }
}
