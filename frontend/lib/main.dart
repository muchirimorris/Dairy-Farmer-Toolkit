import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'src/services/auth_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const DairyFarmerToolkit(),
    ),
  );
}

class DairyFarmerToolkit extends StatelessWidget {
  const DairyFarmerToolkit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dairy Farmer Toolkit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.withOpacity(0.1), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.green.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.withOpacity(0.2), width: 1),
          ),
          color: const Color(0xFF1E1E1E),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
