import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'book_appointment_page.dart';
import 'dart:async'; // Required for StreamSubscription


// Stateful widget for displaying and managing user's appointments

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  // Firebase Realtime Database references
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance.ref("car_appointments");
  final DatabaseReference _branchesRef = FirebaseDatabase.instance.ref("branches");
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";


  // Lists and maps to hold fetched data
  List<Map<String, dynamic>> _appointments = [];
  Map<String, String> _branchNames = {};
  Map<String, String> _branchLocations = {};

  // Default sorting option
  String _sortOption = "time";
  // Channel to invoke platform-specific code
  static const platform = MethodChannel('custom_channel');

  // Loading indicator control
  bool _isLoading = true;
  
  // Subscription to real-time updates from Firebase
  StreamSubscription<DatabaseEvent>? _appointmentSubscription; // Ensure DatabaseEvent is included

  @override
  void initState() {
    super.initState();

	// Ensure appointments are fetched after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppointments(); // Forces Firebase refresh when returning
    });

    _fetchBranches();
  }

  // Fetches branch data from Firebase and stores in maps
  Future<void> _fetchBranches() async {
    _branchesRef.once().then((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final Map<String, String> branchNames = {};
        final Map<String, String> branchLocations = {};
        data.forEach((key, value) {
          branchNames[key] = value["name"] ?? "Unknown Branch";
          branchLocations[key] = value["location"] ?? "";
        });

        setState(() {
          _branchNames = branchNames;
          _branchLocations = branchLocations;
        });
      }
    });
  }

  // Fetches user's appointments and listens for real-time updates
  Future<void> _fetchAppointments() async {
    _appointmentSubscription?.cancel(); // Cancel previous listener

    _isLoading = true; // Ensure loading starts
    setState(() {});

    // Listen for real-time updates
    _appointmentSubscription = _appointmentsRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        setState(() {
          _appointments = [];
          _isLoading = false; // Stop loading even if no data exists
        });
        return;
      }

      // Filter and map user-specific appointments
      final List<Map<String, dynamic>> loadedAppointments = [];
      data.forEach((key, value) {
        if (value is Map && value["userId"] == _currentUserId) {
          loadedAppointments.add({
            "id": key,
            "branch": value["branch"] ?? "",
            "date": value["date"] ?? "9999-12-31",
            "time": value["time"] ?? "23:59",
            "serviceType": value["serviceType"] ?? "Unknown Service", // NEW FIELD
          });
        }
      });

      setState(() {
        _appointments = loadedAppointments;
        _sortAppointments(); // Sort based on selected option
        _isLoading = false; // Ensure loading stops
      });
    }, onError: (error) {
      debugPrint("❌ Firebase Error: $error");
      setState(() {
        _isLoading = false; // Prevents infinite loading even on errors
      });
    });

    // Timeout after 5 seconds if Firebase takes too long
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Opens map or browser with location link using platform channel
  Future<void> _openLocation(String url) async {
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

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Appointments", style: TextStyle(color: Colors.black)),
        centerTitle: true,

        // Sorting Dropdown (Unchanged)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.black),
              onSelected: (String newValue) {
                setState(() {
                  _sortOption = newValue;
                  _sortAppointments(); // Apply sorting immediately
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: "earliest", child: Text("Earliest Date & Time")),
                const PopupMenuItem(value: "latest", child: Text("Latest Date & Time")),
                const PopupMenuItem(value: "alphabetical", child: Text("Sort Alphabetically")),
              ],
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? const Center(
        child: Text(
          "No Appointments Found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      )
          : Scrollbar(
        thickness: 4,
        radius: const Radius.circular(20),
        thumbVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _appointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(_appointments[index]);
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookAppointmentPage()),
          );

          if (result == "refresh") {
            _fetchAppointments(); // Refresh appointments after booking
          }
        },
        backgroundColor: const Color(0xFF001A72),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
  
  // Creates UI card for a single appointment
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final branchId = appointment["branch"];
    final branchName = _branchNames[branchId] ?? "Unknown Branch";
    final serviceType = appointment["serviceType"] ?? "Unknown Service";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Image.asset("assets/Tadaruk logo.png", width: 50, height: 50),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tadaruk Center",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  serviceType, // Show Service Type
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  branchName,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.calendar_today, "Date", appointment["date"]),
                _buildDetailRow(Icons.access_time, "Time", appointment["time"]),
                _buildLocationRow(Icons.location_on, "Location", _branchLocations[branchId] ?? ""),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteAppointment(appointment["id"]),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text("Delete", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build appointment detail row with icon
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            "$label: $value",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper to show a clickable location link
  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.red),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: value.isNotEmpty ? () => _openLocation(value) : null,
            child: Text(
              value.isNotEmpty ? "$label: Tap to open" : "$label: No location available",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  // Deletes an appointment from Firebase
  void _deleteAppointment(String appointmentId) {
    _appointmentsRef.child(appointmentId).remove().then((_) {
      setState(() {
        _appointments.removeWhere((appointment) => appointment["id"] == appointmentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment deleted successfully!")),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting appointment!")),
      );
    });
  }

  // Sorts appointments based on selected option
  void _sortAppointments() {
    if (_sortOption == "earliest") {
      _appointments.sort((a, b) {
        final dateTimeA = DateTime.parse("${a["date"]} ${a["time"]}");
        final dateTimeB = DateTime.parse("${b["date"]} ${b["time"]}");
        return dateTimeA.compareTo(dateTimeB); // Earliest first
      });
    } else if (_sortOption == "latest") {
      _appointments.sort((a, b) {
        final dateTimeA = DateTime.parse("${a["date"]} ${a["time"]}");
        final dateTimeB = DateTime.parse("${b["date"]} ${b["time"]}");
        return dateTimeB.compareTo(dateTimeA); // Latest first
      });
    } else {
      _appointments.sort((a, b) => _branchNames[a["branch"]]!.compareTo(_branchNames[b["branch"]]!));
    }
  }

  // Cancel subscription on widget disposal to avoid memory leaks
  @override
  void dispose() {
    _appointmentSubscription?.cancel(); // Stops Firebase updates when page is closed
    super.dispose();
  }
}
