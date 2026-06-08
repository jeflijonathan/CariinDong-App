import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cariindong_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized) {
      await _googleSignIn.initialize(
        serverClientId: '36334450962-n1v87j55r569lsl8mf3qsrd4eikgpcoe.apps.googleusercontent.com',
      );
      _isGoogleInitialized = true;
    }
  }

  Future<String?> registerUser({
    required UserModel user,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': user.name,
        'email': user.email,
        'profilePicture': '',
        'phoneNumber': user.phoneNumber,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(authProvider);
      } else {
        await _ensureGoogleInitialized();
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        if (googleUser == null) return "Proses dibatalkan";

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final doc = await _db.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) {
          await _db.collection('users').doc(firebaseUser.uid).set({
            'uid': firebaseUser.uid,
            'name': firebaseUser.displayName ?? '',
            'email': firebaseUser.email ?? '',
            'profilePicture': firebaseUser.photoURL ?? '',
            'phoneNumber': firebaseUser.phoneNumber ?? '',
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
