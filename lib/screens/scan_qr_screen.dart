import 'package:flutter/material.dart';

class ScanQRScreen extends StatelessWidget {
  const ScanQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Home Screen',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
