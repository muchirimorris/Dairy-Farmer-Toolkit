import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 add this
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
  User? _user; // 👈 store Firebase user

  @override
  void initState() {
    super.initState();

    // 🔹 Listen to Firebase auth state (login/logout)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });

    // 🔹 Keep splash for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    // 🔹 If user logged in → Dashboard
    // 🔹 Else → Login screen
    if (_user != null) {
      return const DashboardScreen();
    } else {
      return LoginScreen(
        onLogin: () {
          setState(() {
            _user = FirebaseAuth.instance.currentUser;
          });
        },
      );
    }
  }
}
