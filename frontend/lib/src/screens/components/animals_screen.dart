import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:dairy_farmer_toolkit/src/navigation/main_layout.dart';
import 'package:intl/intl.dart';

import '../../models/animal_model.dart';
import '../../repositories/animal_repository.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  final AnimalRepository _animalRepo = AnimalRepository();

  late Stream<List<AnimalModel>> _animalsStream;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      // Trigger a silent background sync
      _animalRepo.syncAnimals(user.id);
      _animalsStream = _animalRepo
          .getAnimalsStream(user.id)
          .asBroadcastStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    return MainLayout(
      selectedIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(
            "🐄 My Livestock",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.add_circle,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
              onPressed: () {
                _showAnimalDialog(context, farmerId: user?.uid);
              },
              tooltip: "Add New Animal",
            ),
          ],
        ),
        body: Column(
          children: [
            // Summary Cards
            _buildSummaryCards(context),
            // Animals List
            Expanded(child: _buildAnimalsList(user?.uid)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<AnimalModel>>(
      stream: _animalsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                _buildSummaryCard("Total", "0", Icons.pets, Colors.blue),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  "Milking",
                  "0",
                  Icons.local_drink,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard("Pregnant", "0", Icons.favorite, Colors.pink),
              ],
            ),
          );
        }

        final animals = snapshot.data!;
        final totalAnimals = animals.length;
        final milkingAnimals = animals.where((animal) {
          return animal.productionStatus.toLowerCase() == "milking";
        }).length;
        final pregnantAnimals = animals.where((animal) {
          return animal.reproductiveStatus.toLowerCase() == "pregnant";
        }).length;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              _buildSummaryCard(
                "Total",
                totalAnimals.toString(),
                Icons.pets,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                "Milking",
                milkingAnimals.toString(),
                Icons.local_drink,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                "Pregnant",
                pregnantAnimals.toString(),
                Icons.favorite,
                Colors.pink,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
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
      ),
    );
  }

  Widget _buildAnimalsList(String? farmerId) {
    if (farmerId == null) return _buildEmptyState();

    return StreamBuilder<List<AnimalModel>>(
      stream: _animalsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading animals: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final animals = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animal = animals[index];

            return _buildAnimalCard(
              context,
              animal.id,
              animal.tagNumber,
              animal.name,
              animal.breed,
              animal.age,
              animal.productionStatus,
              animal.reproductiveStatus,
              animal.lastCalvingDate,
              animal.imageUrl,
              animal.farmerId,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "No Animals Added",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to add your first animal",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(
    BuildContext context,
    String id,
    String tagNumber,
    String name,
    String breed,
    int age,
    String productionStatus,
    String reproductiveStatus,
    String? lastCalvingDate,
    String? imageUrl,
    String farmerId,
  ) {
    Color statusColor = _getStatusColor(productionStatus);
    Color reproColor = _getReproductiveColor(reproductiveStatus);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Animal Image
                CircleAvatar(
                  radius: 30,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : null,
                  backgroundColor: Colors.green.withOpacity(0.2),
                  child: imageUrl == null
                      ? const Icon(Icons.pets, color: Colors.green, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                // Animal Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              productionStatus,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Tag: $tagNumber • Breed: $breed",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        "Age: $age years",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (reproductiveStatus != "Unknown") ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: reproColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: reproColor),
                          ),
                          child: Text(
                            reproductiveStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: reproColor,
                            ),
                          ),
                        ),
                      ],
                      if (lastCalvingDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Last Calving: ${_formatDate(lastCalvingDate)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu Button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      _showAnimalDialog(
                        context,
                        docId: id,
                        currentTagNumber: tagNumber,
                        currentName: name,
                        currentBreed: breed,
                        currentAge: age,
                        currentProductionStatus: productionStatus,
                        currentReproductiveStatus: reproductiveStatus,
                        currentLastCalvingDate: lastCalvingDate,
                        currentImage: imageUrl,
                        farmerId: farmerId,
                      );
                    } else if (value == "delete") {
                      _showDeleteConfirmation(context, id, name);
                    } else if (value == "view_details") {
                      _showAnimalDetails(context, {
                        'name': name,
                        'tagNumber': tagNumber,
                        'breed': breed,
                        'age': age,
                        'productionStatus': productionStatus,
                        'reproductiveStatus': reproductiveStatus,
                        'lastCalvingDate': lastCalvingDate,
                        'imageUrl': imageUrl,
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "view_details",
                      child: Text("📊 View Details"),
                    ),
                    const PopupMenuItem(value: "edit", child: Text("✏️ Edit")),
                    const PopupMenuItem(
                      value: "delete",
                      child: Text("🗑️ Delete"),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Color _getReproductiveColor(String status) {
    switch (status.toLowerCase()) {
      case 'pregnant':
        return Colors.pink;
      case 'open':
        return Colors.orange;
      case 'bred':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showDeleteConfirmation(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Animal"),
        content: Text(
          "Are you sure you want to delete $name? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _animalRepo.deleteAnimal(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name has been deleted"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAnimalDetails(BuildContext context, Map<String, dynamic> animal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${animal['name']} Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (animal['imageUrl'] != null)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(animal['imageUrl']!),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow("Tag Number", animal['tagNumber']),
              _buildDetailRow("Breed", animal['breed']),
              _buildDetailRow("Age", "${animal['age']} years"),
              _buildDetailRow("Production Status", animal['productionStatus']),
              _buildDetailRow(
                "Reproductive Status",
                animal['reproductiveStatus'],
              ),
              if (animal['lastCalvingDate'] != null)
                _buildDetailRow(
                  "Last Calving",
                  _formatDate(animal['lastCalvingDate']!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showAnimalDialog(
    BuildContext context, {
    String? docId,
    String? currentTagNumber,
    String? currentName,
    String? currentBreed,
    int? currentAge,
    String? currentProductionStatus,
    String? currentReproductiveStatus,
    String? currentLastCalvingDate,
    String? currentImage,
    String? farmerId,
  }) {
    if (farmerId == null) return;
    final tagController = TextEditingController(text: currentTagNumber ?? "");
    final nameController = TextEditingController(text: currentName ?? "");
    final ageController = TextEditingController(
      text: currentAge?.toString() ?? "",
    );
    final lastCalvingController = TextEditingController(
      text: currentLastCalvingDate ?? "",
    );
    File? imageFile;
    String? selectedBreed = currentBreed;
    String? selectedProductionStatus = currentProductionStatus ?? "Milking";
    String? selectedReproductiveStatus = currentReproductiveStatus ?? "Unknown";

    final breeds = [
      "Friesian",
      "Jersey",
      "Ayrshire",
      "Guernsey",
      "Sahiwal",
      "Holstein",
      "Brown Swiss",
      "Other",
    ];

    final productionStatuses = ["Milking", "Dry", "Heifer", "Calf"];

    final reproductiveStatuses = ["Pregnant", "Open", "Bred", "Unknown"];

    Future<void> pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        imageFile = File(picked.path);
      }
    }

    Future<void> pickLastCalvingDate() async {
      final initialDate = currentLastCalvingDate != null
          ? DateTime.parse(currentLastCalvingDate!)
          : DateTime.now();

      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );

      if (picked != null) {
        lastCalvingController.text = picked.toIso8601String().split('T')[0];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(docId == null ? "Add New Animal" : "Edit Animal"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text("Take Photo"),
                            onTap: () async {
                              await pickImage(ImageSource.camera);
                              setState(() {});
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text("Choose from Gallery"),
                            onTap: () async {
                              await pickImage(ImageSource.gallery);
                              setState(() {});
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile!)
                        : (currentImage != null
                              ? NetworkImage(currentImage) as ImageProvider
                              : null),
                    backgroundColor: Colors.green[100],
                    child: (imageFile == null && currentImage == null)
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Tag Number
                TextField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    labelText: "Tag Number *",
                    hintText: "e.g., DF-001",
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Animal Name",
                    hintText: "e.g., Daisy",
                  ),
                ),
                const SizedBox(height: 12),

                // Breed
                DropdownButtonFormField<String>(
                  value: selectedBreed,
                  decoration: const InputDecoration(labelText: "Breed *"),
                  items: breeds.map((breed) {
                    return DropdownMenuItem(value: breed, child: Text(breed));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedBreed = val;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Age
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: "Age (years) *"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Production Status
                DropdownButtonFormField<String>(
                  value: selectedProductionStatus,
                  decoration: const InputDecoration(
                    labelText: "Production Status *",
                  ),
                  items: productionStatuses.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedProductionStatus = val;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Reproductive Status
                DropdownButtonFormField<String>(
                  value: selectedReproductiveStatus,
                  decoration: const InputDecoration(
                    labelText: "Reproductive Status",
                  ),
                  items: reproductiveStatuses.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedReproductiveStatus = val;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Last Calving Date
                TextField(
                  controller: lastCalvingController,
                  decoration: InputDecoration(
                    labelText: "Last Calving Date",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: pickLastCalvingDate,
                    ),
                  ),
                  readOnly: true,
                  onTap: pickLastCalvingDate,
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
                // Validation
                if (tagController.text.isEmpty ||
                    selectedBreed == null ||
                    ageController.text.isEmpty ||
                    selectedProductionStatus == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill in all required fields"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                String? imageUrl = currentImage;

                // Upload new image if selected
                if (imageFile != null) {
                  try {
                    // TODO: Implement file upload to Django backend
                    // final ref = FirebaseStorage.instance.ref().child(
                    //   "animals/${DateTime.now().millisecondsSinceEpoch}.jpg",
                    // );
                    // await ref.putFile(imageFile!);
                    // imageUrl = await ref.getDownloadURL();
                  } catch (e) {
                    debugPrint("Error uploading image: $e");
                  }
                }

                final animalModel = AnimalModel(
                  id: docId ?? '', // temporary ID if new
                  tagNumber: tagController.text,
                  name: nameController.text.isNotEmpty
                      ? nameController.text
                      : "Unnamed",
                  breed: selectedBreed!,
                  age: int.tryParse(ageController.text) ?? 0,
                  productionStatus: selectedProductionStatus!,
                  reproductiveStatus: selectedReproductiveStatus!,
                  lastCalvingDate: lastCalvingController.text.isNotEmpty
                      ? lastCalvingController.text
                      : null,
                  imageUrl: imageUrl,
                  farmerId: farmerId,
                );

                try {
                  if (docId == null) {
                    await _animalRepo.addAnimal(animalModel);
                  } else {
                    await _animalRepo.updateAnimal(animalModel);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${nameController.text.isNotEmpty ? nameController.text : 'Animal'} ${docId == null ? 'added' : 'updated'} successfully!",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error saving animal: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Save Animal"),
            ),
          ],
        ),
      ),
    );
  }
}
