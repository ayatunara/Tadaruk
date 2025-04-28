import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddBranchScreen extends StatefulWidget {
  const AddBranchScreen({super.key});

  @override
  _AddBranchScreenState createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('branches');

  List<Map<String, String>> _branches = [];

  @override
  void initState() {
    super.initState();
    _fetchBranches(); // Fetch existing branches from Firebase when the screen loads
  }

  // Fetch branches from Firebase Realtime Database
  void _fetchBranches() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _branches = data.entries.map((entry) {
            final branchData = entry.value;
            if (branchData is Map<dynamic, dynamic>) {
              return {
                'id': branchData['id']?.toString() ?? '',
                'name': branchData['name']?.toString() ?? 'Unknown',
                'location': branchData['location']?.toString() ?? 'Unknown',
              };
            } else {
              return {
                'id': '',
                'name': 'Unknown',
                'location': 'Unknown',
              };
            }
          }).toList();
        });
      } else {
        setState(() {
          _branches = [];
        });
      }
    });
  }

  // Add a new branch to Firebase
  void _addBranch() {
    if (_nameController.text.isNotEmpty && _locationController.text.isNotEmpty) {
      DatabaseReference newBranchRef = _database.push();
      String branchId = newBranchRef.key ?? "";

      newBranchRef.set({
        'id': branchId,
        'name': _nameController.text,
        'location': _locationController.text,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branch added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _nameController.clear();
        _locationController.clear();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text('Branch Management'),
        backgroundColor: Color(0xFF1E1E2E),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
			  // Section: Add a New Branch Title
              "Add a New Branch",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Fill in the details below to add a new branch to the system.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Input fields for branch name and location
            Card(
              color: Color.fromARGB(255, 33, 33, 53),
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
				    // Branch Name Input
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Branch Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.business, color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1E1E2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
					// Location Input
                    TextField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1E1E2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Add Branch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addBranch,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Branch',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 33, 33, 53),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Divider and Section: Existing Branches
            const Divider(color: Colors.white30, thickness: 1),
            const SizedBox(height: 15),
            const Text(
              "Existing Branches",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Display list of existing branches
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(), // Prevents the ListView from scrolling separately
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 10),
              itemCount: _branches.length,
              itemBuilder: (context, index) {
                final branch = _branches[index];
                return Card(
                  color: Color.fromARGB(255, 33, 33, 53),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.white70),
                    title: Text(
                      branch['name']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      "Location: ${branch['location']}",
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
