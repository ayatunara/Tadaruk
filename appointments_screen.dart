// import statements
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Main screen for displaying appointments
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  // Lists to store appointments and filtered appointments
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];

  TextEditingController _searchController = TextEditingController();
  String _selectedSort = "Date (Earliest First)";
  String _selectedStatus = "All";
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _fetchAppointments(); // Fetch appointments from Firebase on startup
  }

// Fetch appointments from Firebase
Future<void> _fetchAppointments() async {
  final snapshot = await _database.child('car_appointments').get();
  final usersSnapshot = await _database.child('users').get();
  final carsSnapshot = await _database.child('cars').get();

  if (snapshot.exists && usersSnapshot.exists && carsSnapshot.exists) {
    // Convert raw snapshot data into Map
    Map<String, dynamic> appointmentsData = Map<String, dynamic>.from(snapshot.value as Map);
    Map<String, dynamic> usersData = Map<String, dynamic>.from(usersSnapshot.value as Map);
    Map<String, dynamic> carsData = Map<String, dynamic>.from(carsSnapshot.value as Map);

    List<Map<String, dynamic>> tempAppointments = [];
    DateTime now = DateTime.now();

    // Loop through each appointment
    appointmentsData.forEach((key, value) {
      String? userId = value['userId'];
      String userName = usersData[userId]?['name'] ?? 'Unknown';
      String phoneNumber = usersData[userId]?['phone'] ?? 'N/A';
      String carModel = 'Unknown';

      // Find the car model associated with this user
      carsData.forEach((key, car) {
        if (car['user_id'] == userId) {
          carModel = car['car_model'];
        }
      });

      String dateStr = value['date'] ?? '';
      String timeStr = value['time'] ?? '';
      DateTime? appointmentDateTime;

      try {
        appointmentDateTime = DateTime.parse("$dateStr $timeStr");
      } catch (e) {
        appointmentDateTime = null;
      }

      // Calculate status based on time
      String calculatedStatus = 'Pending';
      if (appointmentDateTime != null && appointmentDateTime.isBefore(now)) {
        calculatedStatus = 'Confirmed';
      }

      // Add structured appointment to list
      tempAppointments.add({
        'name': userName,
        'phone': phoneNumber,
        'date': dateStr,
        'time': timeStr,
        'carModel': carModel,
        'status': calculatedStatus,
      });
    });

    setState(() {
      _appointments = tempAppointments;
      _filteredAppointments = List.from(_appointments);
    });
  }
}


  // Apply search, status filter, and date filter
  void _applyFilters() {
    setState(() {
      _filteredAppointments = _appointments.where((appointment) {
        if (_selectedStatus != "All" && appointment['status'] != _selectedStatus) return false;
        if (_startDate != null && DateTime.parse(appointment['date']).isBefore(_startDate!)) return false;

        String searchText = _searchController.text.toLowerCase();
        if (searchText.isNotEmpty &&
            !appointment['name'].toLowerCase().contains(searchText) &&
            !appointment['phone'].toLowerCase().contains(searchText) &&
            !appointment['carModel'].toLowerCase().contains(searchText)) {
          return false;
        }
        return true;
      }).toList();
      _sortResults();
    });
  }

  // Sort results based on selected sort type
  void _sortResults() {
    setState(() {
      _filteredAppointments.sort((a, b) {
        switch (_selectedSort) {
          case "Date (Earliest First)":
            return DateTime.parse(a['date']).compareTo(DateTime.parse(b['date']));
          case "Date (Latest First)":
            return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
          case "User Name (A-Z)":
            return a['name'].compareTo(b['name']);
          case "User Name (Z-A)":
            return b['name'].compareTo(a['name']);
          default:
            return 0;
        }
      });
    });
  }
  
  // Reset all filters
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = "All";
      _selectedSort = "Date (Earliest First)";
      _startDate = null;
      _filteredAppointments = List.from(_appointments);
      _sortResults();
    });
  }
 
  //Show a popup dialog for filtering
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter Appointments"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
			  // Dropdown for status filter
              DropdownButton<String>(
                value: _selectedStatus,
                icon: Icon(Icons.filter_alt),
                items: ["All", "Confirmed", "Pending"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
              ),
			  // Date picker for start date filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Start Date:"),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  // Show a popup dialog for sorting
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sort Appointments"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: _selectedSort,
                icon: Icon(Icons.sort),
                items: [
                  "Date (Earliest First)",
                  "Date (Latest First)",
                  "User Name (A-Z)",
                  "User Name (Z-A)"
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedSort = newValue!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _sortResults();
                Navigator.of(context).pop();
              },
              child: Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  // Build a card widget for each appointment
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: Text(appointment['name'], textAlign: TextAlign.center)),
            Expanded(child: Text(appointment['phone'], textAlign: TextAlign.center)),
            Expanded(child: Text(appointment['date'], textAlign: TextAlign.center)),
            Expanded(child: Text(appointment['time'], textAlign: TextAlign.center)),
            Expanded(child: Text(appointment['carModel'], textAlign: TextAlign.center)),
            Expanded(
              child: appointment['status'] == 'Confirmed'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text('Scheduled Appointments'),
        backgroundColor: Color(0xFF1E1E2E),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
			  // Top search bar and filter/sort/reset buttons
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by name, phone, or car model",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) {
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showSortDialog,
                    icon: Icon(Icons.sort),
                    label: Text("Sort"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showFilterDialog,
                    icon: Icon(Icons.filter_alt),
                    label: Text("Filter"),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text("Reset", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
			  // Table header row
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2D3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                    Expanded(child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                    Expanded(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                    Expanded(child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                    Expanded(child: Text('Model', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                    Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
			  // List of appointment cards
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredAppointments.length,
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(_filteredAppointments[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}