import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import '../../models/animal_model.dart';
import '../../models/milk_log_model.dart';
import '../../repositories/animal_repository.dart';
import '../../repositories/milk_log_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnimalRepository _animalRepo = AnimalRepository();
  final MilkLogRepository _milkLogRepo = MilkLogRepository();

  late Stream<List<AnimalModel>> _animalStream;
  late Stream<List<MilkLogModel>> _milkStream;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      _animalStream = _animalRepo
          .getAnimalsStream(user.id)
          .asBroadcastStream();
      _milkStream = _milkLogRepo
          .getMilkLogsStream(user.id)
          .asBroadcastStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return MainLayout(
      selectedIndex:
          2, // Reusing existing index for layout, though it's technically separate
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "📊 Farm Analytics",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blueGrey[800],
        ),
        body: user == null
            ? const Center(child: Text("Please login"))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopPerformersSection(),
                    const SizedBox(height: 24),
                    _buildHerdStatusSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    return StreamBuilder<List<AnimalModel>>(
      stream: _animalStream,
      builder: (context, animalSnapshot) {
        return StreamBuilder<List<MilkLogModel>>(
          stream: _milkStream,
          builder: (context, milkSnapshot) {
            if (!animalSnapshot.hasData || !milkSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final animals = animalSnapshot.data!;
            final logs = milkSnapshot.data!;

            if (animals.isEmpty || logs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Not enough data to calculate top performers."),
                ),
              );
            }

            // Calculate total yield per animal
            Map<String, double> yields = {};
            for (var log in logs) {
              yields[log.animalId] =
                  (yields[log.animalId] ?? 0.0) + log.quantity;
            }

            final sortedYields = yields.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final topAnimals = sortedYields.take(3).toList();
            if (topAnimals.isEmpty) return const SizedBox.shrink();

            final bestAnimalId = topAnimals.first.key;
            final bestAnimal = animals.firstWhere(
              (a) => a.id == bestAnimalId,
              orElse: () => animals.first,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🏆 Top Producer",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.amber[50],
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.amber,
                      child: Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      bestAnimal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    subtitle: Text(
                      "${topAnimals.first.value.toStringAsFixed(1)} L Total Yield",
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Top 3 Animals",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...topAnimals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final animalId = entry.value.key;
                  final amount = entry.value.value;
                  final animalName = animals
                      .firstWhere(
                        (a) => a.id == animalId,
                        orElse: () => animals.first,
                      )
                      .name;

                  return ListTile(
                    leading: CircleAvatar(child: Text("#${index + 1}")),
                    title: Text(
                      animalName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text("${amount.toStringAsFixed(1)} L"),
                  );
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHerdStatusSection() {
    return StreamBuilder<List<AnimalModel>>(
      stream: _animalStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final animals = snapshot.data!;
        Map<String, int> statusCount = {};
        for (var animal in animals) {
          statusCount[animal.productionStatus] =
              (statusCount[animal.productionStatus] ?? 0) + 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🐄 Herd Distribution",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: statusCount.entries.map((entry) {
                    final percent = animals.isNotEmpty
                        ? entry.value / animals.length
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${entry.value} (${(percent * 100).toStringAsFixed(0)}%)",
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
