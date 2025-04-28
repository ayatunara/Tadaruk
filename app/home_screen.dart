import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications_page.dart'; // <-- Import Notifications Page
import 'call_assistance_page.dart';
import 'book_appointment_page.dart';
import 'package:carousel_slider/carousel_slider.dart';



class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase database references
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _carsRef = FirebaseDatabase.instance.ref("cars");
  final DatabaseReference _appointmentsRef = FirebaseDatabase.instance.ref("car_appointments");
  final DatabaseReference _branchesRef = FirebaseDatabase.instance.ref("branches");
  final DatabaseReference _failuresRef = FirebaseDatabase.instance.ref("failures");
final CarouselSliderController _carouselController = CarouselSliderController();
final CarouselSliderController _appointmentsCarouselController = CarouselSliderController();



  String? lastFailureKey;
  // Logged in user's ID
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // State variables
  String? userName;
  List<Map<String, dynamic>> userCars = [];
  List<Map<String, dynamic>> userAppointments = [];
  List<Map<String, dynamic>> userFailures = [];
  Map<String, String> branches = {};
DateTime? lastPopupTime;
  int _currentIndex = 0;
  int _currentAppointmentIndex = 0;


  // Fetch data when the screen initializes
  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUserCars();
    fetchBranches();
    fetchUserAppointments();
    fetchUserFailures();
    _listenForFailures();
  }


// Listen for new failure entries and show popups if there's a new one
void _listenForFailures() async {
  DatabaseReference lastFailureRef = FirebaseDatabase.instance.ref("lastShownFailureKey");

  _failuresRef.limitToLast(1).onChildAdded.listen((event) async {
    if (event.snapshot.value != null) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final newFailureKey = event.snapshot.key; 

      // Get the last shown failure key
      final lastFailureSnapshot = await lastFailureRef.get();
      String? lastFailureKey = lastFailureSnapshot.exists ? lastFailureSnapshot.value.toString() : null;

      // If same failure key as last shown, do not show popup
      if (lastFailureKey == newFailureKey) {
        print("❌ نفس الفشل السابق، لا نعرضه!");
        return;
      }

      // Show popup with new failure data
      _showFailurePopup(data["type"] ?? "Unknown", data["description"] ?? "No details available");

      // Update last shown failure key in database
      await lastFailureRef.set(newFailureKey);
    }
  });
}


  //Show alert dialog when a failure is detected
  void _showFailurePopup(String type, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          titlePadding: EdgeInsets.all(10),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("New Failure Detected", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/car_battery.png", width: 80),
                const SizedBox(height: 10),
                Text("Type: $type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text("Description: $description", textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
				    // Button to call customer service
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        icon: Icon(Icons.phone, color: Colors.white),
                        label: Text("Customer Service", style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CallAssistancePage()));
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
					// Button to book a service appointment
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        icon: Icon(Icons.calendar_today, color: Colors.white),
                        label: Text("Book Appointment", style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(context, MaterialPageRoute(builder: (context) => BookAppointmentPage()));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fetch user info
  Future<void> fetchUserData() async {
    try {
      DatabaseEvent event = await _usersRef.child(userId).once();
      if (event.snapshot.value != null) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          userName = userData["name"] ?? "User";
        });
      } else {
        print("User data not found!");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Fetch user's cars from Firebase
Future<void> fetchUserCars() async {
  try {
    DatabaseEvent event = await _carsRef.orderByChild("user_id").equalTo(userId).once();
    if (event.snapshot.value != null) {
      Map<String, dynamic> cars = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        userCars = cars.values.map((car) => Map<String, dynamic>.from(car)).toList();
      });

      if (userCars.isNotEmpty) {
        fetchUserFailures(); // Refresh failures after cars are fetched
      }
    }
  } catch (e) {
    print("Error fetching car data: $e");
  }
}


  /// Fetch branch names from Firebase
  Future<void> fetchBranches() async {
    try {
      DatabaseEvent event = await _branchesRef.once();
      if (event.snapshot.value != null) {
        Map<String, dynamic> branchesData = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          branches = branchesData.map((key, value) => MapEntry(key, value["name"] ?? "Unknown Branch"));
        });
      }
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  /// Fetch user's last 3 appointments
  Future<void> fetchUserAppointments() async {
    try {
      DatabaseEvent event = await _appointmentsRef.orderByChild("userId").equalTo(userId).once();
      if (event.snapshot.value != null) {
        Map<String, dynamic> appointments = Map<String, dynamic>.from(event.snapshot.value as Map);

        List<Map<String, dynamic>> sortedAppointments = appointments.values
            .map((appt) => Map<String, dynamic>.from(appt))
            .toList()
          ..sort((a, b) => DateTime.parse(b["date"] ?? "2000-01-01").compareTo(DateTime.parse(a["date"] ?? "2000-01-01")));

        setState(() {
          userAppointments = sortedAppointments.take(3).toList();
        });
      }
    } catch (e) {
      print("Error fetching appointments: $e");
    }
  }

//Fetch user's related failure records
Future<void> fetchUserFailures() async {
  try {
    DatabaseEvent event = await _failuresRef.once();
    if (event.snapshot.value != null) {
      Map<String, dynamic> failuresData = Map<String, dynamic>.from(event.snapshot.value as Map);

      List<Map<String, dynamic>> failuresList = failuresData.values
          .map((failure) => Map<String, dynamic>.from(failure))
          .where((failure) => userCars.any((car) => car["id"] == failure["carId"]))
          .toList()
          ..sort((a, b) => DateTime.parse(b["date"] ?? "2000-01-01").compareTo(DateTime.parse(a["date"] ?? "2000-01-01")));

      setState(() {
        userFailures = failuresList.take(3).toList(); // last 3 failures
      });
    }
  } catch (e) {
    print("Error fetching failures: $e");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06258E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Home", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
		  // Notification icon in the app bar
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsPage()),
              );
            },
          ),
        ],

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/profile.png"),
                  ),
                  const SizedBox(width: 12),
                  Column(
				    // welcome message
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text(userName ?? "Loading...", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),


              const SizedBox(height: 20),

              Text("Your Car", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              userCars.isEmpty
                  ? Center(child: Text("🚗 No car data available", style: TextStyle(color: Colors.white)))
                  : Column(
                children: userCars.map((car) {
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left top - Moving Car GIF
                        Expanded(
                          child: Column(
                            children: [
                              Image.asset(
                                "assets/moving_car.gif",  // Replace with your moving car GIF
                                width: double.infinity,  // Makes the GIF take full width
                                height: 75,  // Adjust this as needed
                                fit: BoxFit.contain,  // Ensures GIF fits without being cropped
                              ),
                              const SizedBox(height: 8),
                              // Car Model (Bottom left)
                              Text(
                                "${car["car_model"] ?? car["model"] ?? "Unknown"}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        // Right top - Calendar GIF
                        Expanded(
                          child: Column(
                            children: [
                              Image.asset(
                                "assets/calendar.gif",  // Replace with your calendar GIF
                                width: double.infinity,  // Makes the GIF take full width
                                height: 75,  // Adjust this as needed
                                fit: BoxFit.contain,  // Ensures GIF fits without being cropped
                              ),
                              const SizedBox(height: 8),
                              // Car Year (Bottom right)
                              Text(
                                "${car["car_year"] ?? car["year"] ?? "Unknown"}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 15),
              Text("Recent Failures", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),




userFailures.isEmpty
    // If there are no user failures, show a message
    ? Center(child: Text("⚠️ No failures recorded", style: TextStyle(color: Colors.white)))
    : Column(
        children: [
// Carousel displaying each failure item
CarouselSlider.builder(
   carouselController: _carouselController, 
  options: CarouselOptions(
    height: 110, // يجعل الارتفاع يتكيف مع المحتوى
    autoPlay: false,
    enlargeCenterPage: true,
    viewportFraction: 0.9,
    onPageChanged: (index, reason) {
      setState(() {
        _currentIndex = index;
      });
    },
  ),
  itemCount: userFailures.length,
  itemBuilder: (context, index, realIndex) {
    final failure = userFailures[index];
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 5),
              Text(
                failure["type"] ?? "Unknown",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey, size: 16),
              SizedBox(width: 5),
              Text(
                failure["date"] ?? "Unknown Date",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.article, color: Colors.grey, size: 16),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  failure["description"] ?? "No description",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  },
),


          // Page indicator dots for failures
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: userFailures.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _carouselController.animateToPage(entry.key),
                child: Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key ? Colors.white : Colors.white54,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),

              // Title for appointments section
Text("Recent Appointments", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 10),

// If no appointments, show message
userAppointments.isEmpty
    ? Center(child: Text("📅 No appointments found", style: TextStyle(color: Colors.white)))
    : Column(
        children: [
          CarouselSlider.builder(
            carouselController: _appointmentsCarouselController, 
            options: CarouselOptions(
              height: 110, 
              autoPlay: false,
              enlargeCenterPage: true, 
              viewportFraction: 0.9, 
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemCount: userAppointments.length,
            itemBuilder: (context, index, realIndex) {
              final appointment = userAppointments[index];
              return Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build, color: Colors.blue, size: 18),
                        SizedBox(width: 5),
                        Text(
                          appointment["serviceType"] ?? "Unknown Service",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                        SizedBox(width: 5),
                        Text(
                          "${appointment["date"] ?? "Unknown Date"} - ${appointment["time"] ?? "Unknown Time"}",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey, size: 14),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            "📍 Branch: ${branches[appointment["branch"]] ?? "Unknown"}",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Page indicator dots for appointments
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: userAppointments.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _appointmentsCarouselController.animateToPage(entry.key),
                child: Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key ? Colors.white : Colors.white54,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),

            ],
          ),
        ),
      ),
    );
  }
}