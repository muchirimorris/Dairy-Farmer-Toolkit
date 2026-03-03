import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 👈 add this
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart'; // auto generated
import 'src/navigation/app_navigator.dart';
import 'src/screens/components/dashboard_screen.dart';
import 'src/screens/components/animals_screen.dart';
import 'src/screens/components/milk_logs_screen.dart';
import 'src/screens/components/profile_screen.dart';
import 'src/models/animal_model.dart';
import 'src/models/milk_log_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 required before Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 connects config
  );

  await Hive.initFlutter();
  // Register Adapters
  Hive.registerAdapter(AnimalModelAdapter());
  Hive.registerAdapter(MilkLogModelAdapter());

  // Open boxes
  await Hive.openBox<AnimalModel>('animals');
  await Hive.openBox<MilkLogModel>('milk_logs');

  runApp(const DairyFarmerToolkit());
}

class DairyFarmerToolkit extends StatelessWidget {
  const DairyFarmerToolkit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dairy Farmer Toolkit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AppNavigator(), // Handles Splash → Auth → Dashboard
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/animals': (_) => const AnimalsScreen(),
        '/milkLogs': (_) => const MilkLogsScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
