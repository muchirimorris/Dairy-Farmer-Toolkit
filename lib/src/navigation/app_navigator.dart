import 'package:flutter/material.dart';
import '../screens/components/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/components/dashboard_screen.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool isLoggedIn = false;
  bool _showSplash = true;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    } else {
      return isLoggedIn
          ? const DashboardScreen()
          : LoginScreen(
              onLogin: () {
                setState(() {
                  isLoggedIn = true;
                });
              },
            );
    }
  }
}
