import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This page handles email verification after a user registers.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase authentication instance
  bool _isVerified = false; // Tracks whether the user's email is verified
  Timer? _timer; // Timer used for countdown and periodic verification check
  int _secondsRemaining = 60; // Countdown for resend button reactivation

  @override
  void initState() {
    super.initState();
    _startTimer(); // Start countdown and verification checking
    _checkEmailVerification(); // Initial check when page opens
  }

  // Starts the countdown timer and periodic email verification checks
  void _startTimer() {
    // Timer to update the countdown every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel(); // Stop timer when countdown finishes
      }
    });

    // Timer to check verification status every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (checkTimer) {
	  
      _checkEmailVerification();
      if (_isVerified) {
        checkTimer.cancel();
        _timer?.cancel();
      }
    });
  }

  // Reloads the user from Firebase and checks if their email is verified
  void _checkEmailVerification() async {
    User? user = _auth.currentUser;
    await user?.reload();

    if (user != null && user.emailVerified) {
      setState(() {
        _isVerified = true;
      });
      // Wait 2 seconds then navigate to home page
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  // Sends the verification email again
  void _resendVerificationEmail() async {
    User? user = _auth.currentUser;
    await user?.sendEmailVerification();

    setState(() {
      _secondsRemaining = 60; // Reset countdown for resend button
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📩 Verification email sent again")),
    );
  }

  // Clean up timers when the widget is disposed
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification", style: TextStyle(color: Colors.white, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Color(0xFF001A72),
        iconTheme: IconThemeData(color: Colors.white), // Makes back arrow white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _isVerified
			    // If the user is verified, show confirmation message
                ? Column(
              children: const [
                Icon(Icons.check_circle, color: Color(0xff3e8d42), size: 80),
                SizedBox(height: 10),
                Text(
                  "✅ Your email has been verified!",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Redirecting to home screen...",
                  style: TextStyle(fontSize: 16, color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
              ],
            )
			// If not verified, prompt user to check their email
                : Column(
              children: [
                const Icon(Icons.email, color: Color(0xFF001A72), size: 80),
                const SizedBox(height: 20),
                const Text(
                  "📩 We have sent a verification link to your email.\n"
                      "Please open your email and click the link to verify, then return here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
				// Countdown message for auto-verification or resend button
                Text(
                  "⏳ Auto-verification in $_secondsRemaining seconds...",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
				// Button to manually check verification
                ElevatedButton(
                  onPressed: _checkEmailVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF001A72),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  child: const Text(
                    "Check Again",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
				// Button to resend verification email (only enabled when countdown ends)
                ElevatedButton(
                  onPressed:
                  _secondsRemaining > 0 ? null : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _secondsRemaining > 0
                        ? Colors.grey
                        : Color.fromARGB(255, 90, 74, 143),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  child: const Text(
                    "Resend Email",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
