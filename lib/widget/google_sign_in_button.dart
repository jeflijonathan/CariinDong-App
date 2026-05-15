import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.grey),
      ),
      icon: const FaIcon(FontAwesomeIcons.google, color: Colors.red),
      label: const Text(
        "Masuk dengan Google",
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }
}
