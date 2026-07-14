import 'package:flutter/material.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💰 Finance Management")),
      body: const Center(
        child: Text(
          "Finance features coming soon...",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
