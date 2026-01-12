import 'package:entry_kit/entry_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class MentalHealthAuthRepo implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  MentalHealthAuthRepo({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception("An unexpected error occurred. Please try again.");
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      throw Exception("Registration failed. Please try again.");
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _firebaseAuth.signInWithCredential(credential);
      }
      return googleUser;
    } catch (e) {
      // Returning null cancels the flow gracefully
      return null;
    }
  }

  @override
  Future<AuthorizationCredentialAppleID?> signInWithApple() async {
    // Apple Auth implementation placeholder
    return null;
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'Authentication failed. Please check your connection.';
    }
  }
}