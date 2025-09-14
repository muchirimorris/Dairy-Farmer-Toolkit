import 'package:flutter/material.dart';

class BreedingScreen extends StatelessWidget {
  const BreedingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🐄 Breeding Management")),
      body: const Center(
        child: Text(
          "Breeding features coming soon...",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
