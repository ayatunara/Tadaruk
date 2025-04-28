import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'appointments_screen.dart'; 
import 'profile_screen.dart';


class MainLayout extends StatefulWidget {
  final int initialIndex; // Index to determine which tab is initially selected
  const MainLayout({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; // Keeps track of the selected bottom navigation tab

  final List<Widget> _pages = [
    HomeScreen(),
    AppointmentsPage(), 
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Method to handle tap on bottom navigation bar item
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
	  // App-wide theme customization
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set the primary color theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF001A72),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.white, // Background color of the scaffold
        body: _pages[_selectedIndex], // Display the currently selected page
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // All items are always visible
          backgroundColor: const Color(0xFF001A72), 
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: "Appointment",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
