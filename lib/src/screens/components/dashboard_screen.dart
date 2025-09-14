import 'package:flutter/material.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/breeding_screen.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/finance_screen.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/feed_optimization_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          elevation: 0,
          title: const Text(
            "👩🏾‍🌾 Farmer Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards
              Row(
                children: [
                  _buildStatCard(
                    "Milk (L)",
                    "120",
                    Icons.local_drink,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard("Cows", "15", Icons.pets, Colors.brown),
                ],
              ),
              const SizedBox(height: 16),

              // Chart/Graph Placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "📊 Production Trends (Chart coming soon)",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Feature cards row 1
              Row(
                children: [
                  _buildFeatureCard(
                    context,
                    "Breeding",
                    Icons.favorite,
                    Colors.pink,
                    const BreedingScreen(),
                  ),
                  const SizedBox(width: 12),
                  _buildFeatureCard(
                    context,
                    "Finance",
                    Icons.attach_money,
                    Colors.green,
                    const FinanceScreen(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Feature cards row 2
              Row(
                children: [
                  _buildFeatureCard(
                    context,
                    "Feed Optimization",
                    Icons.grass,
                    Colors.orange,
                    const FeedOptimizationScreen(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Container()), // balance layout
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable stat card
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable feature card
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
