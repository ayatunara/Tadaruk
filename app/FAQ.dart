import 'package:flutter/material.dart';

// A StatelessWidget that builds the FAQ screen
class FAQ extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Set background color for the screen
      appBar: AppBar(
        title: const Text(
          "FAQs", // Title of the app bar
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // Center the title in the app bar
        backgroundColor: const Color(0xFF001A72), // Set app bar background color
        elevation: 0, // Remove shadow from app bar
        iconTheme: const IconThemeData(color: Colors.white), // Set icon color in app bar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // Set padding for the list
        children: _faqItems
            .map((item) => _buildFAQItem(context, item['question']!, item['answer']!))
            .toList(), // Build FAQ items dynamically from the list
      ),
    );
  }

  // Method to build each individual FAQ item using a Card and ExpansionTile
  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Set margin between cards
      elevation: 4, // Set elevation for the card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Round card corners
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: Color(0xFF001A72)), // Icon for FAQ item
        title: Text(
          question, // Display the question
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A1A1A), // Text color for the question
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0), // Padding around the answer
            child: Text(
              answer, // Display the answer
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700], // Text color for the answer
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Static list of FAQs, each item is a map with a 'question' and 'answer'
  final List<Map<String, String>> _faqItems = [
    {"question": "How do I reset my password?", "answer": "Go to the login screen, click 'Forgot Password', and follow the instructions."},
    {"question": "How can I contact support?", "answer": "You can contact support via the 'Contact Us' option in the profile screen."},
    {"question": "How do I update my car information?", "answer": "In your profile, click the edit icon next to the car details and save your changes."},
    {"question": "Can I track my car’s maintenance history?", "answer": "Yes! The app keeps a record of your past appointments and services for easy reference."},
    {"question": "How do I book a car maintenance appointment?", "answer": "You can book an appointment through the 'Book Appointment' page in the app. Select your preferred branch, service type, date, and time."},
    {"question": "Can I cancel or reschedule my appointment?", "answer": "Yes! You can manage your appointments from the 'Appointments' page. Click on the appointment and choose to reschedule or cancel it."},
    {"question": "How do I find the nearest Tadaruk center?", "answer": "You can find our branches in the app by checking your appointment details."},
    {"question": "Can I choose a specific technician for my car?", "answer": "No, but all our technicians are highly trained. Your car will be serviced by the next available expert."},
    {"question": "Can I request a specific service if it’s not listed in the app?", "answer": "Some branches may allow custom service requests. Contact the branch directly for special requests."},
    {"question": "What types of cars do you service?", "answer": "We service most makes and models. If you have a specialized vehicle, contact the branch to confirm."},
    {"question": "Can I track my car’s service progress in real time?", "answer": "Not yet, but we’re working on adding live tracking for service progress in future updates."},
    {"question": "Is there a late fee if I arrive late to my appointment?", "answer": "It depends on the branch policy. Some may allow a grace period, while others may require rescheduling."},
    {"question": "Can I leave my car overnight at the service center?", "answer": "Some branches offer overnight storage, but you should confirm with the location before your visit."},
  ];
}
