import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();
  static final AuthService I = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// Stream current user
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send OTP to phone. Returns verificationId
  Future<String> sendOtp({
    required String e164Phone, // e.g. +9198XXXXXXXX
    int? forceResendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      forceResendingToken: forceResendToken,
      timeout: timeout,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval (Android). You can sign in silently if you want:
        // await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Ignored – we already resolve on codeSent
      },
    );
    return completer.future;
  }

  /// Verify OTP and sign in. Also creates/updates user doc.
  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? displayName,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final uc = await _auth.signInWithCredential(credential);

    // Bootstrap user profile in Firestore
    final u = uc.user!;
    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final appUser = AppUser(
        uid: u.uid,
        phone: u.phoneNumber ?? '',
        email: u.email,
        displayName: displayName ?? u.displayName,
        role: 'user',
      );
      await ref.set(appUser.toMap(), SetOptions(merge: true));
    } else {
      // Ensure role is present
      await ref.set(
          {'phone': u.phoneNumber, 'email': u.email}, SetOptions(merge: true));
    }
    return uc;
  }

  Future<void> signOut() => _auth.signOut();

  // Optional email helpers
  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);
}
