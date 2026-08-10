import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/animal_model.dart';
import '../../models/milk_log_model.dart';
import '../../models/health_record_model.dart';
import '../../models/financial_record_model.dart';

import '../../repositories/milk_log_repository.dart';
import '../../repositories/health_repository.dart';
import '../../repositories/finance_repository.dart';
import '../../services/auth_service.dart';

class AnimalDetailsScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalDetailsScreen({super.key, required this.animal});

  @override
  State<AnimalDetailsScreen> createState() => _AnimalDetailsScreenState();
}

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> {
  final MilkLogRepository _milkLogRepo = MilkLogRepository();
  final HealthRepository _healthRepo = HealthRepository();
  final FinanceRepository _financeRepo = FinanceRepository();

  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'milking':
        return Colors.green;
      case 'dry':
        return Colors.orange;
      case 'heifer':
        return Colors.blue;
      case 'calf':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final farmerId = user?.id ?? '';
    final animal = widget.animal;
    final statusColor = _getStatusColor(animal.productionStatus);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${animal.name} Details"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.water_drop), text: "Milk Logs"),
              Tab(icon: Icon(Icons.medical_services), text: "Health"),
              Tab(icon: Icon(Icons.attach_money), text: "Finances"),
            ],
          ),
        ),
        body: Column(
          children: [
            // Profile Header Section
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: animal.imageUrl != null ? NetworkImage(animal.imageUrl!) : null,
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: animal.imageUrl == null ? const Icon(Icons.pets, color: Colors.green, size: 40) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              animal.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                animal.productionStatus,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tag: ${animal.tagNumber} • Breed: ${animal.breed}",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Age: ${animal.age} yrs • Repro: ${animal.reproductiveStatus}",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                        if (animal.lastCalvingDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Last Calving: ${_formatDate(animal.lastCalvingDate)}",
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildMilkLogsTab(farmerId),
                  _buildHealthTab(farmerId),
                  _buildFinanceTab(farmerId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilkLogsTab(String farmerId) {
    return StreamBuilder<List<MilkLogModel>>(
      stream: _milkLogRepo.getMilkLogsStream(farmerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No milk logs found for this animal.");
        }

        final logs = snapshot.data!.where((log) => log.animalId == widget.animal.id).toList();
        if (logs.isEmpty) {
          return _buildEmptyState("No milk logs found for this animal.");
        }

        // Sort by date descending
        logs.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blueAccent),
                title: Text("${log.quantity} Liters", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat("MMM dd, yyyy 'at' hh:mm a").format(log.date)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHealthTab(String farmerId) {
    return StreamBuilder<List<HealthRecordModel>>(
      stream: _healthRepo.getHealthRecordsStream(farmerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No health records found.");
        }

        final records = snapshot.data!.where((rec) => rec.animalId == widget.animal.id).toList();
        if (records.isEmpty) {
          return _buildEmptyState("No health records found.");
        }

        records.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final rec = records[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.redAccent),
                title: Text(rec.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat("MMM dd, yyyy").format(rec.date)),
                    Text(rec.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFinanceTab(String farmerId) {
    return StreamBuilder<List<FinancialRecordModel>>(
      stream: _financeRepo.getFinancialRecordsStream(farmerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No financial records found.");
        }

        final records = snapshot.data!.where((rec) => rec.animalId == widget.animal.id).toList();
        if (records.isEmpty) {
          return _buildEmptyState("No financial records found.");
        }

        records.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final rec = records[index];
            final isIncome = rec.type.toLowerCase() == 'income';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
                title: Text("\$${rec.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${rec.category}\n${DateFormat("MMM dd, yyyy").format(rec.date)}"),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
