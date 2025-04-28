import 'package:flutter/material.dart';

class TipsGuides extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Set background color for the screen
      appBar: AppBar(
        title: const Text(
          "Tips & Guides", // Title of the app bar
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // Center the title in the app bar
        backgroundColor: const Color(0xFF001A72), // Set app bar background color
        elevation: 0, // Remove shadow from app bar
        iconTheme: const IconThemeData(color: Colors.white), // Set icon color in app bar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // Set padding for the list
        children: _tips
            .map((tip) => _buildTipItem(context, tip['title']!, tip['description']!))
            .toList(), // Build tip items dynamically from the list
      ),
    );
  }

  // Build individual tip item
  Widget _buildTipItem(BuildContext context, String title, String description) {
    return Card(
      elevation: 3, // Set elevation for the card
      shadowColor: Colors.black12, // Set shadow color for the card
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Set margin between cards
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Round card corners
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Set padding for the list tile
        leading: const Icon(Icons.check_circle, color: Color(0xFF001A72), size: 28), // Icon for the tip item

        title: Text(
          title, // Display the title of the tip
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1A1A1A), // Text color for the title
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4), // Padding for the description text
          child: Text(
            description, // Display the description of the tip
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700], // Text color for the description
            ),
          ),
        ),
      ),
    );
  }

  // List of tips, each containing a title and description
  final List<Map<String, String>> _tips = [
    {"title": "Regular Car Maintenance", "description": "Check your engine oil, coolant, and tire pressure regularly."},
    {"title": "Battery Care", "description": "Avoid leaving electrical components on when the engine is off to extend battery life."},
    {"title": "Fuel Efficiency", "description": "Drive smoothly and avoid sudden acceleration to improve fuel economy."},
    {"title": "Brake System Check", "description": "Inspect your brakes every 6 months to ensure safety."},
    {"title": "Tire Rotation", "description": "Rotate your tires every 5,000 to 8,000 miles to ensure even wear."},
    {"title": "Check Engine Light", "description": "If your check engine light is on, run a diagnostic test to identify the issue."},
    {"title": "Air Filter Replacement", "description": "Replace your air filter every 12,000 to 15,000 miles to improve engine performance."},
    {"title": "Safe Driving in Rain", "description": "Slow down and increase your following distance when driving in wet conditions."},
    {"title": "Avoid Overloading", "description": "Carrying excess weight can reduce fuel efficiency and strain the suspension."},
    {"title": "Wiper Blade Maintenance", "description": "Replace windshield wipers every 6-12 months for clear visibility."},
    {"title": "Engine Cooling System", "description": "Regularly check your radiator and coolant levels to prevent overheating."},
    {"title": "Use the Right Fuel", "description": "Always use the recommended fuel type to prevent engine damage."},
    {"title": "Transmission Fluid Check", "description": "Check and change your transmission fluid as per manufacturer recommendations."},
    {"title": "Parking in the Shade", "description": "Protect your car’s paint and interior by parking in the shade or using a sunshade."},
    {"title": "Winter Car Preparation", "description": "Check your battery, tires, and antifreeze levels before winter begins."},
    {"title": "Battery Degradation", "description": "Monitor battery health regularly to prevent performance degradation and ensure reliable power."},
    {"title": "Thermal Runaway in Battery", "description": "Ensure proper ventilation and cooling to avoid thermal runaway, which can lead to battery failure."},
    {"title": "Lubrication System Failure", "description": "Check and maintain oil levels regularly to prevent lubrication failure in the engine."},
    {"title": "Cooling System Failure", "description": "Regularly inspect your cooling system to avoid overheating and ensure proper engine performance."},
  ];
}
