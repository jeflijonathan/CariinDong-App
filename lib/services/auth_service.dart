import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cariindong_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        'fullName': user.fullName,
        'email': user.email,
        'profilePictureUrl': '',
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
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
            .authenticate();
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
            'fullName': firebaseUser.displayName ?? '',
            'email': firebaseUser.email ?? '',
            'profilePictureUrl': firebaseUser.photoURL ?? '',
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
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
