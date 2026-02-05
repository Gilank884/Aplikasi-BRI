import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'data_screen.dart';
import 'account_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DataScreen(),
    AccountScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: const Color(0xFF00529C),
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const ScanQRScreen()),
      //     );
      //   },
      //   child: const Icon(Icons.qr_code_scanner),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
