import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import 'package:dairy_farmer_toolkit/src/screens/auth/login_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    print("🔑 Current Firebase User: ${user?.uid}");

    return MainLayout(
      selectedIndex: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[700],
          elevation: 0,
          title: const Text(
            "👤 Farmer Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        body: user == null
            ? _buildNotLoggedInState(context)
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("farmers")
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print("❌ Firestore Error: ${snapshot.error}");
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    print("⚠️ No profile data found for UID: ${user.uid}");
                    return _buildNoProfileDataState(context, user);
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  print("✅ Profile data loaded: $data");

                  return _buildProfileContent(context, data, user);
                },
              ),
      ),
    );
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Not Logged In",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please log in to view your profile",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => LoginScreen(onLogin: () {}),
                ),
                (route) => false,
              );
            },
            child: const Text("Go to Login"),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            "Error Loading Profile",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Loading your profile..."),
        ],
      ),
    );
  }

  Widget _buildNoProfileDataState(BuildContext context, User user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_add, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "Profile Not Set Up",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "User ID: ${user.uid}",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please complete your farmer profile to get started",
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showSetupProfileDialog(context, user),
            icon: const Icon(Icons.person_add),
            label: const Text("Set Up Profile"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetupProfileDialog(BuildContext context, User user) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController farmNameController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController experienceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Setup Your Farmer Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide your farm details to get started."),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Your Name *",
                  border: OutlineInputBorder(),
                  hintText: "e.g., John Dairy",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: farmNameController,
                decoration: const InputDecoration(
                  labelText: "Farm Name *",
                  border: OutlineInputBorder(),
                  hintText: "e.g., Green Valley Dairy Farm",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Farm Location",
                  border: OutlineInputBorder(),
                  hintText: "e.g., Nakuru, Kenya",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  hintText: "e.g., +254712345678",
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: "Years of Experience",
                  border: OutlineInputBorder(),
                  hintText: "e.g., 5",
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || farmNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please fill in required fields (Name and Farm Name)"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _createProfile(
                context,
                user.uid,
                user.email!,
                nameController.text,
                farmNameController.text,
                locationController.text,
                phoneController.text,
                experienceController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Save Profile"),
          ),
        ],
      ),
    );
  }

  Future<void> _createProfile(
    BuildContext context,
    String userId,
    String email,
    String name,
    String farmName,
    String location,
    String phone,
    String experience,
  ) async {
    try {
      final profileData = {
        "name": name,
        "email": email,
        "farmName": farmName,
        "location": location.isNotEmpty ? location : "Not specified",
        "phone": phone.isNotEmpty ? phone : "Not provided",
        "experience": experience.isNotEmpty ? experience : "0",
        "joinDate": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection("farmers")
          .doc(userId)
          .set(profileData);

      Navigator.pop(context); // Close the dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Profile created successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error creating profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> data, User user) {
    final name = data["name"] ?? "Unknown Farmer";
    final email = data["email"] ?? user.email ?? "No email available";
    final phone = data["phone"] ?? "Not provided";
    final farmName = data["farmName"] ?? "Not set";
    final location = data["location"] ?? "Not set";
    final experience = data["experience"] ?? "0";
    final profileImage = data["profileImage"];
    final joinDate = data["joinDate"] != null 
        ? (data["joinDate"] as Timestamp).toDate()
        : user.metadata.creationTime;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green[100],
                        backgroundImage: profileImage != null 
                            ? CachedNetworkImageProvider(profileImage) as ImageProvider
                            : null,
                        child: profileImage == null 
                            ? const Icon(Icons.person, size: 50, color: Colors.green)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (farmName != "Not set") ...[
                    const SizedBox(height: 8),
                    Text(
                      farmName,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          _buildStatsSection(data, user.uid),
          const SizedBox(height: 20),

          // Farm Information
          _buildFarmInfoSection(farmName, location, phone, experience, joinDate),
          const SizedBox(height: 20),

          // Actions Section
          _buildActionsSection(context, user.uid),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> data, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("animals")
          .where("farmerId", isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int totalAnimals = 0;
        int milkingAnimals = 0;
        
        if (snapshot.hasData) {
          final animals = snapshot.data!.docs;
          totalAnimals = animals.length;
          milkingAnimals = animals.where((doc) {
            final animal = doc.data() as Map<String, dynamic>;
            return (animal["productionStatus"] ?? "").toString().toLowerCase() == "milking";
          }).length;
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "📊 Farm Overview",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(totalAnimals.toString(), "Total Animals", Icons.pets, Colors.blue),
                    _buildStatCard(milkingAnimals.toString(), "Milking", Icons.local_drink, Colors.green),
                    _buildStatCard((data["experience"] ?? "0").toString(), "Years", Icons.work, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmInfoSection(String farmName, String location, String phone, String experience, DateTime? joinDate) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🏠 Farm Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, "Farm Name", farmName),
            _buildInfoRow(Icons.location_on, "Location", location),
            _buildInfoRow(Icons.phone, "Phone", phone),
            _buildInfoRow(Icons.work, "Experience", "$experience years"),
            if (joinDate != null)
              _buildInfoRow(
                Icons.calendar_today,
                "Member since",
                DateFormat('MMM yyyy').format(joinDate),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, String userId) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("Edit Profile"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEditProfileDialog(context, userId),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text("Settings"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings feature coming soon!")),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.grey),
            title: const Text("Help & Support"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Help feature coming soon!")),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection("farmers").doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data() as Map<String, dynamic>;

    final TextEditingController nameController = TextEditingController(text: data["name"] ?? "");
    final TextEditingController farmNameController = TextEditingController(text: data["farmName"] ?? "");
    final TextEditingController locationController = TextEditingController(text: data["location"] ?? "");
    final TextEditingController phoneController = TextEditingController(text: data["phone"] ?? "");
    final TextEditingController experienceController = TextEditingController(text: data["experience"]?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Your Name *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: farmNameController,
                decoration: const InputDecoration(
                  labelText: "Farm Name *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Farm Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: "Years of Experience",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || farmNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please fill in required fields"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection("farmers").doc(userId).update({
                  "name": nameController.text,
                  "farmName": farmNameController.text,
                  "location": locationController.text,
                  "phone": phoneController.text,
                  "experience": experienceController.text,
                  "updatedAt": FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Profile updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Error updating profile: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => LoginScreen(onLogin: () {}),
                ),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}