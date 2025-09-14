import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection("farmers")
        .doc(user.uid)
        .get();

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          elevation: 0,
          title: const Text(
            "👤 Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // TODO: Navigate to settings
              },
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No profile data found"));
            }

            final data = snapshot.data!;
            final name = data["name"] ?? "Unknown Farmer";
            final location = data["location"] ?? "Location not set";
            final cows = data["cows"]?.toString() ?? "0";
            final milkPerDay = data["milkPerDay"]?.toString() ?? "0 L";
            final experience = data["experience"]?.toString() ?? "0 yrs";
            final profileImage =
                data["profileImage"] ??
                "https://via.placeholder.com/150"; // default placeholder

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: CachedNetworkImageProvider(profileImage),
                  ),
                  const SizedBox(height: 12),

                  // Farmer Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(cows, "Cows"),
                      _buildStat(milkPerDay, "Milk/day"),
                      _buildStat(experience, "Experience"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionTile(
                    icon: Icons.edit,
                    title: "Edit Profile",
                    subtitle: "Update your information",
                    onTap: () {
                      // TODO: Navigate to Edit Profile
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.lock,
                    title: "Change Password",
                    subtitle: "Update your account security",
                    onTap: () {
                      // TODO: Change password
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.logout,
                    title: "Logout",
                    subtitle: "Sign out of your account",
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      // TODO: Navigate back to login screen
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
