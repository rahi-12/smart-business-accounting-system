import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService _instance = FirebaseAuthService._();

  factory FirebaseAuthService() => _instance;

  FirebaseAuth? get _auth {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseAuth.instance;
  }

  User? get currentUser => _auth?.currentUser;

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'No Firebase App has been created yet.',
      );
    }

    return auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'no-app',
        message: 'No Firebase App has been created yet.',
      );
    }

    return auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) {
      return;
    }

    await auth.signOut();
  }

  Future<String?> getIdToken() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    return user.getIdToken();
  }

  Future<void> reloadCurrentUser() async {
    final user = _auth?.currentUser;
    if (user == null) {
      return;
    }

    await user.reload();
  }
}
