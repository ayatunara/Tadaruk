import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'call_assistance_page.dart';

import 'FAQ.dart';
import 'tips_guides.dart';


// Main profile screen widget
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Firebase instances for authentication and database
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // User information variables
  String userName = "Loading...";
  String userEmail = "Loading...";
  String userPhone = "Loading...";
  String carModel = "Loading...";
  String carYear = "Loading...";

  // Text controllers for editing fields
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController carModelController = TextEditingController();
  TextEditingController carYearController = TextEditingController();

  // Booleans to toggle edit mode
  bool isEditingName = false;
  bool isEditingPhone = false;
  bool isEditingCarModel = false;
  bool isEditingCarYear = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetch user and car data from Firebase
  Future<void> _fetchUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
	  // Get user data
      DatabaseEvent userEvent = await _database.child("users").child(user.uid).once();
      if (userEvent.snapshot.value != null) {
        Map<dynamic, dynamic> userData = userEvent.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          userName = userData["name"] ?? "No Name";
          userEmail = userData["email"] ?? "No Email";
          userPhone = userData["phone"] ?? "No Phone";
          nameController.text = userName;
          phoneController.text = userPhone;
        });
      }
      // Get car data
      DatabaseEvent carEvent = await _database.child("cars").orderByChild("user_id").equalTo(user.uid).once();
      if (carEvent.snapshot.value != null) {
        Map<dynamic, dynamic> carsData = carEvent.snapshot.value as Map<dynamic, dynamic>;
        if (carsData.isNotEmpty) {
          var firstCar = carsData.values.first;
          setState(() {
            carModel = firstCar["car_model"] ?? "Unknown";
            carYear = firstCar["car_year"] ?? "Unknown";
            carModelController.text = carModel;
            carYearController.text = carYear;
          });
        }
      }
    }
  }

  // Update user or car data in Firebase
  Future<void> _updateUserProfile(String field, String newValue) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DatabaseReference userRef = _database.child("users").child(user.uid);
    DatabaseReference carRef = _database.child("cars");

    if (field == "Name") {
      await userRef.update({"name": newValue});
    } else if (field == "Phone Number") {
      await userRef.update({"phone": newValue});
    } else if (field == "Car Model") {
      DatabaseEvent carEvent = await carRef.orderByChild("user_id").equalTo(user.uid).once();
      if (carEvent.snapshot.value != null) {
        Map<dynamic, dynamic> carsData = carEvent.snapshot.value as Map<dynamic, dynamic>;
        if (carsData.isNotEmpty) {
          String carKey = carsData.keys.first;
          await carRef.child(carKey).update({"car_model": newValue});
        }
      }
    } else if (field == "Car Year") {
      DatabaseEvent carEvent = await carRef.orderByChild("user_id").equalTo(user.uid).once();
      if (carEvent.snapshot.value != null) {
        Map<dynamic, dynamic> carsData = carEvent.snapshot.value as Map<dynamic, dynamic>;
        if (carsData.isNotEmpty) {
          String carKey = carsData.keys.first;
          await carRef.child(carKey).update({"car_year": newValue});
        }
      }
    }
  }

// Sign out the user
Future<void> _signOut() async {
  User? user = _auth.currentUser;

  if (user != null) {
    DatabaseReference userRef = _database.child("users").child(user.uid);
	// Remove FCM token on logout
    
    
    await userRef.update({"fcm_token": null});
    print("🚪 تم تسجيل الخروج وحذف FCM Token للمستخدم: ${user.uid}");
  }

  await _auth.signOut(); 

  if (!mounted) return;

  // Navigate to login page
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("User Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF001A72),
      ),
      body: Scrollbar(
        thickness: 4, // Slim scrollbar
        radius: const Radius.circular(20), // Rounded edges
        thumbVisibility: true, // Always visible when scrolling
        interactive: true, // Allows dragging the scrollbar
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(radius: 50, backgroundImage: const AssetImage("assets/profile.png")),
              const SizedBox(height: 20),

			  // Section for user information
              _buildSectionTitle("About Me"),
              _buildEditableField(Icons.person, nameController, "Name", isEditingName, () async {
                await _updateUserProfile("Name", nameController.text);
                setState(() => isEditingName = !isEditingName);
              }),
              _buildNonEditableField(Icons.email, userEmail, "E-mail Address"),
              _buildEditableField(Icons.phone, phoneController, "Phone Number", isEditingPhone, () async {
                await _updateUserProfile("Phone Number", phoneController.text);
                setState(() => isEditingPhone = !isEditingPhone);
              }),

			  // Section for car information
              _buildSectionTitle("Car Information"),
              _buildEditableField(Icons.directions_car, carModelController, "Car Model", isEditingCarModel, () async {
                await _updateUserProfile("Car Model", carModelController.text);
                setState(() => isEditingCarModel = !isEditingCarModel);
              }),
              _buildEditableField(Icons.calendar_today, carYearController, "Car Year", isEditingCarYear, () async {
                await _updateUserProfile("Car Year", carYearController.text);
                setState(() => isEditingCarYear = !isEditingCarYear);
              }),

              // Settings section
              _buildSectionTitle("Settings"),
              _buildProfileItem(Icons.help, "FAQs", "Frequently Asked Questions", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FAQ()));
              }),
              _buildProfileItem(Icons.lightbulb, "Tips & Guides", "Helpful Tips", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TipsGuides()));
              }),

              _buildProfileItem(Icons.phone_in_talk, "Contact Us", "Reach Out", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CallAssistancePage()));
              }),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Sign Out", style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showPrivacyPolicyDialog, // Opens popup
                child: const Text(
                  "Privacy & Policy",
                  style: TextStyle(color: Colors.blue, fontSize: 14, decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      )
    );
  }

  // Section title widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  // Editable input field with icon and save/edit toggle
  Widget _buildEditableField(IconData icon, TextEditingController controller, String label, bool isEditing, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFE8F0FF), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade900),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: controller, enabled: isEditing)),
            IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.edit, color: Colors.blue),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }

  // Clickable profile item with icon and forward arrow
  Widget _buildProfileItem(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFE8F0FF), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue.shade900),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade600, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Non-editable display field
  Widget _buildNonEditableField(IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFE8F0FF), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue.shade900),
            const SizedBox(width: 10),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // Show privacy policy in a dialog
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Privacy & Policy"),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => Navigator.pop(context), // Close button
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              "Your privacy is important to us. This app collects minimal personal data "
                  "necessary for its function and does not share it with third parties.",
              textAlign: TextAlign.center, // Centers the text
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity, // Makes the button take full width
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white30, // Light blue background
                ),
                child: const Text("OK", style: TextStyle(color: Colors.blue)),
              ),
            ),
          ],
        );
      },
    );
  }
}