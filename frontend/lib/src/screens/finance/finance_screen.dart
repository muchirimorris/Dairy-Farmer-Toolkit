import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import '../../models/financial_record_model.dart';
import '../../repositories/finance_repository.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final FinanceRepository _financeRepo = FinanceRepository();
  late Stream<List<FinancialRecordModel>> _financeStream;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      _financeRepo.syncFinances(user.id);
      _financeStream = _financeRepo
          .getFinancialRecordsStream(user.id)
          .asBroadcastStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return MainLayout(
      selectedIndex: 3, // Finance is index 3
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: const Text(
            "💰 Finance",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
              onPressed: () {
                _showTransactionDialog(context, farmerId: user?.id);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSummaryCards(context),
            Expanded(child: _buildTransactionList(user?.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return StreamBuilder<List<FinancialRecordModel>>(
      stream: _financeStream,
      builder: (context, snapshot) {
        double income = 0;
        double expenses = 0;

        if (snapshot.hasData) {
          for (var record in snapshot.data!) {
            if (record.type == 'income') {
              income += record.amount;
            } else {
              expenses += record.amount;
            }
          }
        }

        double balance = income - expenses;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              _buildSummaryCard(
                "Income",
                "+\$${income.toStringAsFixed(2)}",
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                "Expenses",
                "-\$${expenses.toStringAsFixed(2)}",
                Colors.red,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                "Balance",
                "\$${balance.toStringAsFixed(2)}",
                Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(String? farmerId) {
    if (farmerId == null) return const Center(child: Text("Please login"));

    return StreamBuilder<List<FinancialRecordModel>>(
      stream: _financeStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedRecords = snapshot.data!.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (sortedRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  "No Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedRecords.length,
          itemBuilder: (context, index) {
            final record = sortedRecords[index];
            final isIncome = record.type == 'income';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncome
                      ? Colors.green[100]
                      : Colors.red[100],
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  record.category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(record.date)),
                trailing: Text(
                  "${isIncome ? "+" : "-"}\$${record.amount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                ),
                onLongPress: () {
                  // Add delete/edit option
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Record"),
                      content: const Text(
                        "Are you sure you want to delete this transaction?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            _financeRepo.deleteRecord(
                              record.id,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionDialog(BuildContext context, {String? farmerId}) {
    if (farmerId == null) return;
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    String type = 'expense';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Transaction"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text("Income"),
                      selected: type == 'income',
                      onSelected: (val) => setState(() => type = 'income'),
                      selectedColor: Colors.green[200],
                    ),
                    ChoiceChip(
                      label: const Text("Expense"),
                      selected: type == 'expense',
                      onSelected: (val) => setState(() => type = 'expense'),
                      selectedColor: Colors.red[200],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    prefixText: "\$",
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    hintText: "e.g., Feed, Milk Sale",
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Description (Optional)",
                  ),
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
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0 || categoryController.text.isEmpty) return;

                final record = FinancialRecordModel(
                  id: '',
                  farmerId: farmerId,
                  type: type,
                  amount: amount,
                  category: categoryController.text,
                  description: descriptionController.text,
                  date: DateTime.now(),
                );
                await _financeRepo.addRecord(record);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
