import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beranda"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(
                user?.photoURL ?? "https://via.placeholder.com/150",
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Halo, ${user?.displayName ?? 'User'}!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("${user?.email}"),
            const SizedBox(height: 30),
            const Text("Selamat datang di aplikasi kamu."),
          ],
        ),
      ),
    );
  }
}
