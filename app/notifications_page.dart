import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// NotificationsPage is a StatefulWidget that displays notifications related to a user's car
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Reference to the Firebase Realtime Database
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? userCarId;
  
  // List of notifications to display
  List<Map<String, String>> notifications = [];

  
  @override
  void initState() {
    super.initState();
	// Fetch the user's car ID when the page is initialized
    _fetchUserCarId();
  }

  // Fetch the user's car ID from the database based on their Firebase Auth UID
  Future<void> _fetchUserCarId() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final DatabaseReference carsRef = _database.child("cars");
    final DataSnapshot snapshot = await carsRef.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> carsData = snapshot.value as Map<dynamic, dynamic>;

      // Iterate through each car entry
      for (var car in carsData.entries) {
        if (car.value["user_id"] == user.uid) {
          setState(() {
            userCarId = car.value["id"];
          });
		  // Start listening for failures related to this car
          _listenForFailures(userCarId!);
          break;
        }
      }
    }
  }

  // Listen for new failure notifications for the specified car ID
  void _listenForFailures(String carId) {
    _database.child("failures").orderByChild("carId").equalTo(carId).onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
		// Add the notification to the top of the list
        setState(() {
          notifications.insert(0, {
            "type": data["type"] ?? "Unknown",
            "date": data["date"] ?? "Unknown Date",
            "description": data["description"] ?? "No details available"
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
	  // AppBar with a title and back button
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 39, 142),

        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: userCarId == null
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? const Center(
                        child: Text("No notifications yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      )
                    : Scrollbar(
                        child: ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(notifications[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Build a single notification item widget
  Widget _buildNotificationItem(Map<String, String> notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
		  // Display appropriate image based on notification type
          Image.asset(
            notification["type"] == "Engine" ? "assets/car_engine.png" : "assets/car_battery.png",
            width: 40,
          ),
          const SizedBox(width: 10),
		  // Display notification title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification["type"] ?? "Unknown Type",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  notification["description"] ?? "No details available",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
		  // Display the date of the notification
          Text(notification["date"] ?? "", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
