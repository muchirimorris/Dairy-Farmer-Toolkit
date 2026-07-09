import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/feed_inventory_model.dart';
import '../../repositories/feed_repository.dart';

class FeedOptimizationScreen extends StatefulWidget {
  const FeedOptimizationScreen({super.key});

  @override
  State<FeedOptimizationScreen> createState() => _FeedOptimizationScreenState();
}

class _FeedOptimizationScreenState extends State<FeedOptimizationScreen> {
  final FeedRepository _feedRepo = FeedRepository();
  late Stream<List<FeedInventoryModel>> _feedStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _feedRepo.syncFeedInventory(user.uid);
      _feedStream = _feedRepo
          .getFeedInventoryStream(user.uid)
          .asBroadcastStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[600],
        title: Text(
          "🌿 Feed Optimization",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_shopping_cart,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showAddFeedDialog(context, user?.uid),
            tooltip: "Add Feed Stock",
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Please login to manage feed."))
          : _buildFeedList(user.uid),
    );
  }

  Widget _buildFeedList(String farmerId) {
    return StreamBuilder<List<FeedInventoryModel>>(
      stream: _feedStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final inventory = snapshot.data!;
        if (inventory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grass,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 16),
                Text(
                  "No Feed Inventory",
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
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final item = inventory[index];
            final percentLeft = item.threshold > 0
                ? (item.quantity / (item.threshold * 3)).clamp(0.0, 1.0)
                : 1.0;
            final isLow = item.quantity <= item.threshold;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (isLow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Low Stock",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      item.type,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Available: ${item.quantity.toStringAsFixed(1)} ${item.unit}",
                        ),
                        Text(
                          "Threshold: ${item.threshold} ${item.unit}",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentLeft,
                      backgroundColor: Colors.grey[200],
                      color: isLow ? Colors.red : Colors.green,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showConsumeDialog(context, farmerId, item),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                          ),
                          label: const Text("Log Feed"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.brown,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _deleteFeedItem(context, farmerId, item),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddFeedDialog(BuildContext context, String? farmerId) {
    if (farmerId == null) return;

    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final thresholdController = TextEditingController();
    String type = 'Hay';
    String unit = 'kg';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add New Feed"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Feed Name (e.g. Alfalfa)",
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: "Type"),
                  items: ['Hay', 'Silage', 'Concentrate', 'Minerals']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        decoration: const InputDecoration(
                          labelText: "Initial Quantity",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: unit,
                        decoration: const InputDecoration(labelText: "Unit"),
                        items: ['kg', 'bales', 'tons', 'bags']
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => unit = v!),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: thresholdController,
                  decoration: const InputDecoration(
                    labelText: "Low Stock Alert Threshold",
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
                final name = nameController.text.trim();
                final qty = double.tryParse(qtyController.text) ?? 0;
                final threshold =
                    double.tryParse(thresholdController.text) ?? 0;

                if (name.isNotEmpty && qty > 0) {
                  final item = FeedInventoryModel(
                    id: '',
                    type: type,
                    name: name,
                    quantity: qty,
                    unit: unit,
                    cost: 0,
                    purchaseDate: DateTime.now(),
                    threshold: threshold,
                  );
                  await _feedRepo.addFeedItem(farmerId, item);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showConsumeDialog(
    BuildContext context,
    String farmerId,
    FeedInventoryModel item,
  ) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Consume ${item.name}"),
        content: TextField(
          controller: qtyController,
          decoration: InputDecoration(
            labelText: "Amount to deduct (${item.unit})",
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final deduct = double.tryParse(qtyController.text) ?? 0;
              if (deduct > 0 && deduct <= item.quantity) {
                final updatedItem = item.copyWith(
                  quantity: item.quantity - deduct,
                );
                await _feedRepo.updateFeedItem(farmerId, updatedItem);
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _deleteFeedItem(
    BuildContext context,
    String farmerId,
    FeedInventoryModel item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Feed Item?"),
        content: const Text(
          "This will permanently remove the item from inventory.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _feedRepo.deleteFeedItem(farmerId, item.id);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
