import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'view_cars_screen.dart';
import 'add_branch_screen.dart';
import 'appointments_screen.dart';
import 'add_features_screen.dart';
import 'add_sensor_data_screen.dart'; 

//main function to initialize firebase and run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBEn3UcR9Vs18tozEg6LRjxcNAEmzrPf84", // Firebase API key
      authDomain: "tadurkdata.firebaseapp.com", // Firebase authentication domain
      databaseURL: "https://tadurkdata-default-rtdb.firebaseio.com", // Firebase database URL
      projectId: "tadurkdata",
      storageBucket: "tadurkdata.appspot.com",
      messagingSenderId: "217624737030",
      appId: "1:217624737030:web:426c6bf84fc89d6ea71a87",
      measurementId: "G-NQB1G5B6KB",
    ),
  );
  runApp(const MyApp()); // Run the app after Firebase initialization
}

// MyApp class is the root of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Cars and Users',
      theme: ThemeData.dark(),
      home: const NavigationLayout(), // Define the default home screen with navigation layout
      debugShowCheckedModeBanner: false, // Disable the debug banner in the app
    );
  }
}

// NavigationLayout is a StatefulWidget to manage navigation between screens
class NavigationLayout extends StatefulWidget {
  const NavigationLayout({super.key});

  @override
  State<NavigationLayout> createState() => _NavigationLayoutState();
}

class _NavigationLayoutState extends State<NavigationLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const ViewCarsScreen(),
    const AddBranchScreen(),
    const AppointmentsScreen(),
    const AddFeaturesScreen(), //Predictive features page (added feature)
    const AddSensorDataScreen(), // Sensor data page (added feature)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
		  // Navigation Rail for selecting different screens
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            groupAlignment: -0.2,
            backgroundColor: const Color(0xFF2A2D3E),
            selectedIconTheme: const IconThemeData(color: Colors.blue, size: 30),
            unselectedIconTheme: const IconThemeData(color: Colors.grey, size: 24),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home), label: SizedBox.shrink()),
              NavigationRailDestination(icon: Icon(Icons.directions_car), label: SizedBox.shrink()),
              NavigationRailDestination(icon: Icon(Icons.store), label: SizedBox.shrink()),
              NavigationRailDestination(icon: Icon(Icons.calendar_today), label: SizedBox.shrink()),
              NavigationRailDestination(icon: Icon(Icons.analytics), label: SizedBox.shrink()), // Predictive analytics icon destination
              NavigationRailDestination(icon: Icon(Icons.input), label: SizedBox.shrink()), // Sensor data input icon destination
            ],
            labelType: NavigationRailLabelType.none, // Hide labels, only icons
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _pages[_selectedIndex]), // Display the selected page based on index
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to build the top bar of the app
  Widget _buildTopBar() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF2A2D3E),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 20,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Hello Admin', // Display admin greeting text
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
