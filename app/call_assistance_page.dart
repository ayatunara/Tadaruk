import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Main stateless widget for the Call Assistance Page
class CallAssistancePage extends StatelessWidget {
  const CallAssistancePage({Key? key}) : super(key: key);

  // Define a method channel for communicating with native platform code
  static const platform = MethodChannel('custom_channel');

  // Method to launch external URLs using the method channel
  Future<void> _launchIntent(String url) async {
    try {
      await platform.invokeMethod('openLink', {"url": url});
    } catch (e) {
      debugPrint("❌ Error launching $url: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top car image that spans 35% of screen height
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: Image.asset(
              "assets/Car_image.png", // Ensure the image is in the assets folder
              fit: BoxFit.cover,
            ),
          ),

          // Custom back button positioned at the top-left
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.155,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF3A5A98),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(75),
                ),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 15, left: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous screen
                    },
                  ),
                ),
              ),
            ),
          ),

          // Main content stacked below the image
          Column(
            children: [
              const SizedBox(height: 300), //  Spacer to push content below the image

              // العنوان (تم نقله للأسفل)
              const Text(
                "Call for Assistance",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001A72),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Assistance icon in a circular blue background
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Icon(Icons.headset_mic, size: 40, color: Colors.white),
              ),

              const SizedBox(height: 30),

              // Contact buttons for different methods
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
				    // Twitter contact button
                    _buildContactButton(
                      Icons.alternate_email,
                      "@_TADARUK_",
                      "https://twitter.com/_TADARUK_",
                    ),
					// Email contact button
                    _buildContactButton(
                      Icons.email,
                      "TADARUK@gmail.com",
                      "mailto:TADARUK@gmail.com",
                    ),
					// Phone contact button
                    _buildContactButton(
                      Icons.phone,
                      "+966 53 213 8248",
                      "tel:+966532138248",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable method to create a contact button with an icon and text
  Widget _buildContactButton(IconData icon, String text, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        onPressed: () => _launchIntent(url), // Launch intent when button is pressed
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF001A72),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
