import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/breeding_screen.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/finance_screen.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/feed_optimization_screen.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/animals_screen.dart';
import 'package:dairy_farmer_toolkit/src/screens/components/milk_logs_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<QuerySnapshot> _animalsStream;
  late Stream<QuerySnapshot> _milkLogsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _animalsStream = FirebaseFirestore.instance
          .collection("animals")
          .where("farmerId", isEqualTo: user.uid)
          .snapshots();

      _milkLogsStream = FirebaseFirestore.instance
          .collection("farmers")
          .doc(user.uid)
          .collection("milk_logs")
          .orderBy("date", descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MainLayout(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.green[700],
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
              onPressed: () => _showNotifications(context),
              tooltip: "Notifications",
            ),
          ],
        ),
        body: user == null 
            ? _buildNotLoggedInState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(context),
                    const SizedBox(height: 20),

                    // Quick Stats Row
                    _buildQuickStatsSection(),
                    const SizedBox(height: 20),

                    // Milk Production Line Chart
                    _buildMilkProductionLineChart(),
                    const SizedBox(height: 20),

                    // Today's Overview
                    _buildTodaysOverview(),
                    const SizedBox(height: 20),

                    // Feature Grid
                    _buildFeatureGrid(context),
                    const SizedBox(height: 20),

                    // Recent Activity
                    _buildRecentActivity(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNotLoggedInState() {
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
            "Please log in to view your dashboard",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("farmers")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String farmerName = "Farmer";
        String farmName = "Your Farm";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          farmerName = data["name"]?.toString().split(" ").first ?? "Farmer";
          farmName = data["farmName"] ?? "Your Farm";
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Good ${_getTimeOfDayGreeting()}, $farmerName! 👋",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        farmName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Here's your farm overview for today",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.agriculture, color: Colors.green, size: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _animalsStream,
      builder: (context, snapshot) {
        int totalAnimals = 0;
        int milkingAnimals = 0;
        int pregnantAnimals = 0;

        if (snapshot.hasData) {
          final animals = snapshot.data!.docs;
          totalAnimals = animals.length;
          milkingAnimals = animals.where((doc) {
            final animal = doc.data() as Map<String, dynamic>;
            return (animal["productionStatus"] ?? "").toString().toLowerCase() == "milking";
          }).length;
          pregnantAnimals = animals.where((doc) {
            final animal = doc.data() as Map<String, dynamic>;
            return (animal["reproductiveStatus"] ?? "").toString().toLowerCase() == "pregnant";
          }).length;
        }

        return Row(
          children: [
            _buildStatCard(
              "Total Animals",
              totalAnimals.toString(),
              Icons.pets,
              Colors.blue,
              "All livestock",
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              "Milking Now",
              milkingAnimals.toString(),
              Icons.local_drink,
              Colors.green,
              "In production",
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              "Pregnant",
              pregnantAnimals.toString(),
              Icons.favorite,
              Colors.pink,
              "Expecting calves",
            ),
          ],
        );
      },
    );
  }

  Widget _buildMilkProductionLineChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _milkLogsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildChartPlaceholder("Loading milk data...");
        }

        final logs = snapshot.data!.docs;
        if (logs.isEmpty) {
          return _buildChartPlaceholder("No milk data available");
        }

        final chartData = _prepareChartData(logs);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "📈 Milk Production Trend",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Last 7 Days",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  child: _buildSimpleLineChart(chartData),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleLineChart(List<MilkProductionData> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final maxValue = data.map((e) => e.liters).reduce((a, b) => a > b ? a : b);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          // Chart area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final heightPercentage = maxValue > 0 ? (item.liters / maxValue) : 0;
                
                return Expanded(
                  child: Column(
                    children: [
                      // Value label
                      Text(
                        "${item.liters.toStringAsFixed(1)}L",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 100.0 * heightPercentage, // Fixed: changed 100 to 100.0
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.green[400]!,
                              Colors.green[700]!,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Day label
                      Text(
                        item.day,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MilkProductionData> _prepareChartData(List<QueryDocumentSnapshot> logs) {
    final now = DateTime.now();
    final Map<String, double> dailyProduction = {};

    // Initialize last 7 days with day names
    final List<String> dayNames = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('E').format(date);
      dayNames.add(key);
      dailyProduction[key] = 0.0;
    }

    // Sum milk production by day
    for (var doc in logs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data["date"] as Timestamp).toDate();
      final quantity = (data["quantity"] as num).toDouble();
      
      if (date.isAfter(now.subtract(const Duration(days: 7)))) {
        final key = DateFormat('E').format(date);
        dailyProduction[key] = (dailyProduction[key] ?? 0.0) + quantity;
      }
    }

    // Convert to chart data format in correct order
    final List<MilkProductionData> result = [];
    for (final day in dayNames) {
      result.add(MilkProductionData(day, dailyProduction[day] ?? 0.0));
    }

    return result;
  }

  Widget _buildTodaysOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _milkLogsStream,
      builder: (context, snapshot) {
        double todaysMilk = 0.0;
        int todaysLogs = 0;

        if (snapshot.hasData) {
          final today = DateTime.now();
          final logs = snapshot.data!.docs;
          
          todaysLogs = logs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data["date"] as Timestamp).toDate();
            return date.year == today.year &&
                   date.month == today.month &&
                   date.day == today.day;
          }).length;

          todaysMilk = logs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = (data["date"] as Timestamp).toDate();
                return date.year == today.year &&
                       date.month == today.month &&
                       date.day == today.day;
              })
              .fold(0.0, (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)["quantity"] as num).toDouble());
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.today, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Today's Production",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTodaysStat("Milk Collected", "${todaysMilk.toStringAsFixed(1)} L", Icons.local_drink),
                    _buildTodaysStat("Milk Sessions", "$todaysLogs", Icons.list_alt),
                    _buildTodaysStat("Avg per Session", todaysLogs > 0 ? "${(todaysMilk / todaysLogs).toStringAsFixed(1)} L" : "0 L", Icons.analytics),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            "Farm Management",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildFeatureCard(
              context,
              "My Animals",
              Icons.pets,
              Colors.blue,
              const AnimalsScreen(),
              "Manage livestock",
            ),
            _buildFeatureCard(
              context,
              "Milk Logs",
              Icons.local_drink,
              Colors.green,
              const MilkLogsScreen(),
              "Record production",
            ),
            _buildFeatureCard(
              context,
              "Breeding",
              Icons.favorite,
              Colors.pink,
              const BreedingScreen(),
              "Track reproduction",
            ),
            _buildFeatureCard(
              context,
              "Finance",
              Icons.attach_money,
              Colors.orange,
              const FinanceScreen(),
              "Income & expenses",
            ),
            _buildFeatureCard(
              context,
              "Feed Optimization",
              Icons.grass,
              Colors.brown,
              const FeedOptimizationScreen(),
              "Manage feeding",
            ),
            _buildFeatureCard(
              context,
              "Health Records",
              Icons.medical_services,
              Colors.red,
              Container(),
              "Animal health",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: _milkLogsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final logs = snapshot.data!.docs;
        if (logs.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.local_drink, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "No recent milk logs",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final recentLogs = logs.take(3).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recentLogs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final quantity = data["quantity"];
                  final animalName = data["animalName"] ?? "Unknown";
                  final date = (data["date"] as Timestamp).toDate();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_drink, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$quantity L from $animalName",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(date),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (screen is! Container) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$title feature coming soon!")),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No new notifications")),
    );
  }
}

class MilkProductionData {
  final String day;
  final double liters;

  MilkProductionData(this.day, this.liters);
}