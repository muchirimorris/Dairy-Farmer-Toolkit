import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 👈 add this
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart'; // auto generated
import 'src/navigation/app_navigator.dart';
import 'src/screens/components/dashboard_screen.dart';
import 'src/screens/components/animals_screen.dart';
import 'src/screens/components/milk_logs_screen.dart';
import 'src/screens/components/profile_screen.dart';
import 'src/screens/finance/finance_screen.dart';
import 'src/models/animal_model.dart';
import 'src/models/milk_log_model.dart';
import 'src/models/financial_record_model.dart';
import 'src/models/feed_inventory_model.dart';
import 'src/models/health_record_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 👈 required before Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 connects config
  );

  await Hive.initFlutter();
  // Register Adapters
  Hive.registerAdapter(AnimalModelAdapter());
  Hive.registerAdapter(MilkLogModelAdapter());
  Hive.registerAdapter(FinancialRecordModelAdapter());
  Hive.registerAdapter(FeedInventoryModelAdapter());
  Hive.registerAdapter(HealthRecordModelAdapter());

  // Open boxes
  await Hive.openBox<AnimalModel>('animals');
  await Hive.openBox<MilkLogModel>('milk_logs');
  await Hive.openBox<FinancialRecordModel>('financial_records');
  await Hive.openBox<FeedInventoryModel>('feed_inventory');
  await Hive.openBox<HealthRecordModel>('health_records');

  runApp(const DairyFarmerToolkit());
}

class DairyFarmerToolkit extends StatelessWidget {
  const DairyFarmerToolkit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dairy Farmer Toolkit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.lightGreen,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AppNavigator(), // Handles Splash → Auth → Dashboard
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/animals': (_) => const AnimalsScreen(),
        '/milkLogs': (_) => const MilkLogsScreen(),
        '/finance': (_) => const FinanceScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
