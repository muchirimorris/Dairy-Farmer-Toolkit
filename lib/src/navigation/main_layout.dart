import 'package:flutter/material.dart';
import 'package:dairy_farmer_toolkit/src/navigation/bottom_nav.dart';

class MainLayout extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const MainLayout({
    super.key,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNav(
        currentIndex: selectedIndex,
        onTabSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/animals');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/milkLogs');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/finance');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
