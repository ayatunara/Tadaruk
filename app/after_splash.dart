import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// This widget represents the screen shown after the splash screen.
class AfterSplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
	// Set the system UI overlay style to make the status bar transparent
    // and its icons dark
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Keeps the status bar background transparent
      statusBarIconBrightness: Brightness.dark, // Makes the icons black
    ));
    return Scaffold(
	  // SafeArea ensures that UI elements do not overlap system UI like the notch or status bar.
      body: SafeArea(
        child: Stack(
          children: [
			// Positioned container at the bottom to show a colored background panel.
            Align(			
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4, // Takes 40% of screen height
                decoration: const BoxDecoration(
                  color: Color(0xFF001A72), // Dark blue background
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20), // Rounded top left corner
                    topRight: Radius.circular(20), // Rounded top right corner
                  ),
                ),
              ),
            ),
			
			// Main content column
            Column(
              children: [
                const SizedBox(height: 100), // Adds vertical spacing to push content down
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
					// App logo image
                    Image.asset(
                      'assets/Tadaruk logo.png',
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.width * 0.5,
                    ),
                    const SizedBox(height: 5), // Space between image and text
                    // App slogan text
					Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'No Need to Guess.\nTadaruk Predicts, You Drive.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3), // Soft shadow for better readability
                              offset: Offset(2, 2), 
                              blurRadius: 4, 
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const Spacer(), // Pushes the following content to the bottom of the screen
                // Login and Sign Up buttons section
				Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login'); // Navigate to Login screen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Rounded button shape
                            ),
                            minimumSize: const Size(250, 50),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF001A72),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Space between buttons
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup'); // Navigate to Sign Up screen
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(250, 50),
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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
