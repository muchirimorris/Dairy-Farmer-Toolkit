import 'package:flutter/material.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';

class AnimalsScreen extends StatelessWidget {
  const AnimalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          elevation: 0,
          title: const Text(
            "🐄 My Animals",
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
                // TODO: Add new animal
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnimalCard("Daisy", "Friesian", 4, Colors.brown),
            _buildAnimalCard("Bella", "Jersey", 3, Colors.orange),
            _buildAnimalCard("Max", "Ayrshire", 2, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(String name, String breed, int age, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.pets, color: color),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text("Breed: $breed • Age: $age years"),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: () {
          // TODO: Navigate to animal details screen
        },
      ),
    );
  }
}
