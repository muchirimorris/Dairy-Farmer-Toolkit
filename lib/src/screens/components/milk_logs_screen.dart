import 'package:flutter/material.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';

class MilkLogsScreen extends StatelessWidget {
  const MilkLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          elevation: 0,
          title: const Text(
            "🥛 Milk Logs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white),
              onPressed: () {
                // TODO: Navigate to Add Milk Log screen
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMilkLogCard("Daisy", "12 L", "2025-09-14", Colors.blue),
            _buildMilkLogCard("Bella", "9 L", "2025-09-13", Colors.orange),
            _buildMilkLogCard("Max", "10.5 L", "2025-09-12", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildMilkLogCard(
    String cow,
    String quantity,
    String date,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.local_drink, color: color),
        ),
        title: Text(
          "$cow - $quantity",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text("Date: $date"),
        trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
        onTap: () {
          // TODO: Open log details / edit screen
        },
      ),
    );
  }
}
