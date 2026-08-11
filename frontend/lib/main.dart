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

  try {
    await Hive.initFlutter();
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AnimalModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MilkLogModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FinancialRecordModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(FeedInventoryModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(HealthRecordModelAdapter());

    Future<void> safeOpenBox<T>(String boxName) async {
      try {
        await Hive.openBox<T>(boxName);
      } catch (e) {
        debugPrint('Failed to open $boxName, wiping and retrying: $e');
        try {
          await Hive.deleteBoxFromDisk(boxName);
        } catch (deleteError) {
          debugPrint('Ignored error during deletion of $boxName: $deleteError');
        }
        await Hive.openBox<T>(boxName);
      }
    }

    // Open boxes
    await safeOpenBox<AnimalModel>('animals');
    await safeOpenBox<MilkLogModel>('milk_logs');
    await safeOpenBox<FinancialRecordModel>('financial_records');
    await safeOpenBox<FeedInventoryModel>('feed_inventory');
    await safeOpenBox<HealthRecordModel>('health_records');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const DairyFarmerToolkit(),
      ),
    );
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  'App Initialization Error:\n$e\n\n$stackTrace',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        scaffoldBackgroundColor: const Color(0xFFF4F4F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          primary: const Color(0xFF22C55E),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF1F2937),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF22C55E),
          unselectedItemColor: Color(0xFF9CA3AF),
          elevation: 8,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA3E635),
          primary: const Color(0xFFA3E635),
          onPrimary: Colors.black,
          surface: const Color(0xFF18181B),
          onSurface: const Color(0xFFFAFAFA),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: const Color(0xFFFAFAFA),
          displayColor: const Color(0xFFFAFAFA),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF18181B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF27272A), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF27272A),
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
            borderSide: const BorderSide(color: Color(0xFFA3E635), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA3E635),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF18181B),
          selectedItemColor: Color(0xFFA3E635),
          unselectedItemColor: Color(0xFFA1A1AA),
          elevation: 8,
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
