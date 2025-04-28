import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'main_layout.dart';
import 'appointments_screen.dart'; // Make sure this import is at the top of your file

// Main page to book a car appointment
class BookAppointmentPage extends StatefulWidget {
  @override
  _BookAppointmentPageState createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final DatabaseReference _appointmentsRef =
  FirebaseDatabase.instance.ref().child('car_appointments');
  final DatabaseReference _branchesRef =
  FirebaseDatabase.instance.ref().child('branches');
  final User? _currentUser = FirebaseAuth.instance.currentUser; // Current logged-in user

  List<Map<String, String>> _branches = [];
  String? _selectedBranch;
  String? _selectedServiceType;
  final List<String> _serviceTypes = [
    "Battery Degradation",
    "Battery Thermal Runaway",
    "Engine Cooling System",
    "Engine Lubrication System"
  ];
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  Set<String> _bookedTimes = {}; // Stores booked times

  final List<String> availableTimes = [ // Static list of available time slots
    "09:00", "09:30", "10:00", "10:30",
    "11:00", "11:30", "12:00", "12:30",
    "13:00", "13:30", "14:00", "14:30",
    "15:00", "15:30", "16:00", "16:30",
    "17:00"
  ];

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  // Fetch branch data from Firebase
  Future<void> _fetchBranches() async {
    _branchesRef.once().then((DatabaseEvent event) {
      Map<dynamic, dynamic>? branchesMap = event.snapshot.value as Map?;
      if (branchesMap != null) {
        setState(() {
          _branches = branchesMap.entries.map((entry) {
            return {
              "id": entry.key.toString(),
              "name": entry.value["name"].toString(),
              "location": entry.value["location"].toString(),
            };
          }).toList();
        });
      }
    }).catchError((error) {
      print("Error fetching branches: $error");
    });
  }

  // Fetch booked times for selected date and branch
  Future<void> _fetchBookedTimes() async {
    if (_selectedBranch == null) return;

    _appointmentsRef
        .orderByChild("branch")
        .equalTo(_selectedBranch)
        .once()
        .then((DatabaseEvent event) {
      Map<dynamic, dynamic>? appointmentsMap = event.snapshot.value as Map?;
      Set<String> bookedTimes = {};

      if (appointmentsMap != null) {
        appointmentsMap.forEach((key, value) {
          if (value["date"] == DateFormat('yyyy-MM-dd').format(_selectedDate)) {
            bookedTimes.add(value["time"]);
          }
        });
      }

      setState(() {
        _bookedTimes = bookedTimes;
      });
    }).catchError((error) {
      print("Error fetching booked times: $error");
    });
  }

  // Handle change of selected date and update booked times
  void _changeDate(DateTime newDate) {
    setState(() {
      _selectedDate = DateTime.utc(
        newDate.year,
        newDate.month,
        newDate.day,
      );
      _fetchBookedTimes(); // Refresh booked times when changing date
    });
  }

  // Save the appointment in Firebase
  void _saveAppointment() {
    if (_selectedBranch != null && _selectedTime != null && _selectedServiceType != null && !_bookedTimes.contains(_selectedTime)) {
      _appointmentsRef.push().set({
        "userId": _currentUser!.uid,
        "branch": _selectedBranch,
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "time": _selectedTime,
        "serviceType": _selectedServiceType,
      }).then((_) async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Appointment booked sucessfully ✅"),
      backgroundColor: Colors.green,
    ),
  );
  _fetchBookedTimes(); // Refresh list after booking

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => MainLayout(initialIndex: 1)), 
    (route) => false,
  );
})


.catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred while booking!")),
        );
      });
    }
  }

  // Main UI builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book an Appointment", style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF001C72),
        iconTheme: IconThemeData(color: Colors.white), // Makes back arrow white
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

// Header section with icon and description
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Icon(Icons.event, color: Color(0xFF001C72)), 
        SizedBox(width: 8), 
        Text(
          "Schedule Your Car Service",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001C72),
          ),
        ),
      ],
    ),
    SizedBox(height: 4),
    Text(
      "Book an appointment at your preferred branch, choose a date, and select an available time slot.",
      style: TextStyle(
        fontSize: 16,
        color: Colors.black87, 
      ),
    ),
    SizedBox(height: 18), 
  ],
),

            // Branch selector
            Text("🔍 Select a branch"),
            DropdownButtonFormField<String>(
              value: _selectedBranch,
              items: _branches.map((branch) {
                return DropdownMenuItem<String>(
                  value: branch["id"],
                  child: Text(branch["name"]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBranch = value;
                  _fetchBookedTimes(); // Refresh booked times when selecting a branch
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
			// Service type selector
            Text("🛠 Select a Service Type"),
            DropdownButtonFormField<String>(
              value: _selectedServiceType,
              items: _serviceTypes.map((service) {
                return DropdownMenuItem<String>(
                  value: service,
                  child: Text(service),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServiceType = value;
                });
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
			// date selector
            Text("📅 Select a date"),
            SizedBox(height: 8),
            InkWell(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 30)),
                );

                if (pickedDate != null) {
                  _changeDate(pickedDate);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFF001C72), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF001C72),
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Color(0xFF001C72)), // Calendar icon
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),
            // time selector
            Text("⏰ Select a time"),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: availableTimes.length,
              itemBuilder: (context, index) {
                String time = availableTimes[index];
                bool isBooked = _bookedTimes.contains(time);
                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.grey
                          : (_selectedTime == time ? Color(0xFF001C72) : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isBooked ? Colors.grey : Color(0xFF001C72)),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isBooked
                            ? Colors.white
                            : (_selectedTime == time ? Colors.white : Color(0xFF001C72)),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 18),
// Book button
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _saveAppointment,
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF001C72),
      padding: EdgeInsets.symmetric(vertical: 12),
    ),
    child: Text(
      "Book Appointment",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  ),
),

          ],
        ),
      ),
    );
  }
}
