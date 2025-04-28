import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _scanPosition = 0;
  bool _isMovingRight = true; // Direction of scanning animation

  @override
  void initState() {
    super.initState();

    // Set status bar to match the background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Move the scanning bar back & forth
    Timer.periodic(const Duration(milliseconds: 700), (timer) {
      setState(() {
        _scanPosition = _isMovingRight ? 80 : -80;
        _isMovingRight = !_isMovingRight;
      });
    });

    // Check if user is logged in & navigate
    Future.delayed(const Duration(seconds: 5), _checkUserStatus);
  }

  void _checkUserStatus() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacementNamed(context, '/home'); // Logged in
    } else {
	  // If not logged in or email not verified, go to after splash screen
      Navigator.pushReplacementNamed(context, '/after_splash'); // Not logged in
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with fade-in animation
              AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: 1.0,
                child: Image.asset(
                  'assets/Tadaruk logo.png',
                  width: 250,
                  height: 250,
                ),
              ),
              const SizedBox(height: 30),

              // Scanning Bar (Moves left & right)
              Container(
                width: 200,
                height: 4,
                color: const Color.fromARGB(255, 79, 76, 100).withOpacity(0.2),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 700),
                      left: _scanPosition,
                      child: Container(
                        width: 40,
                        height: 4,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
			  // Splash screen message text
              const Text(
                "Analyzing Vehicle Health...",
                style: TextStyle(
                  color: Color.fromARGB(179, 13, 14, 79),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}