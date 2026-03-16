import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/bni.png',
              width: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Column(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFFFA6400),
                      size: 90,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'BNI',
                      style: TextStyle(
                        color: Color(0xFFFA6400),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
