import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/components/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/components/dashboard_screen.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // 🔹 Keep splash for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.currentUser != null) {
          return const DashboardScreen();
        } else {
          return LoginScreen(
            onLogin: () {
              // Login state handled by AuthService
            },
          );
        }
      },
    );
  }
}
