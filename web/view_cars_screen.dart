import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ViewCarsScreen extends StatefulWidget {
  const ViewCarsScreen({super.key});

  @override
  State<ViewCarsScreen> createState() => _ViewCarsScreenState();
}

class _ViewCarsScreenState extends State<ViewCarsScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _carsList = []; // List of all cars fetched from database
  List<Map<String, dynamic>> _filteredCars = [];
  String _selectedSort = "Model (A-Z)"; // Default sorting option
  String _selectedBrand = "All"; // Default filter option
  int? _startYear; // Year filter

  @override
  void initState() {
    super.initState();
    _fetchCars(); // Fetch car data when screen is initialized
  }

  // Function to fetch car data from the Firebase database
  void _fetchCars() {
    _database.child('cars').onValue.listen((event) async {
      final carsData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (carsData != null) {
        List<Map<String, dynamic>> tempCarsList = [];

        // Fetch failures data from Firebase
        final failuresSnapshot = await _database.child('failures').get();
        final failuresData = failuresSnapshot.value as Map<dynamic, dynamic>? ?? {};

        for (var entry in carsData.entries) {
          final key = entry.key;
          final value = entry.value as Map<dynamic, dynamic>;
          final userID = value['user_id'] ?? 'No UserID';

          // Fetch user data for each car
          final userSnapshot = await _database.child('users/$userID').get();
          final userData = userSnapshot.value as Map<dynamic, dynamic>?;

          List<Map<String, dynamic>> carFailures = [];
		  // Check for failures related to the current car
          failuresData.forEach((failureKey, failureValue) {
            if (failureValue['carId'] == key) {
              carFailures.add({
                'type': failureValue['type'] ?? 'Unknown',
                'description': failureValue['description'] ?? 'No Description',
              });
            }
          });

          // If there are no failures, add a default entry
          if (carFailures.isEmpty) {
            carFailures.add({'type': 'None', 'description': 'No Failures'});
          }

          // Add car data along with user and failure information to the temp list
          for (var failure in carFailures) {
            tempCarsList.add({
              'model': value['car_model'] ?? 'No Model',
              'year': value['car_year'] ?? 'No Year',
              'userName': userData?['name'] ?? 'No Name',
              'userPhone': userData?['phone'] ?? 'No Phone',
              'userEmail': userData?['email'] ?? 'No Email',
              'failureType': failure['type'],
              'failureDesc': failure['description'],
            });
          }
        }

        setState(() {
          _carsList = tempCarsList;
          _filteredCars = _carsList;
        });
      } else {
        setState(() {
          _carsList = [];
          _filteredCars = [];
        });
      }
    });
  }

  // Function to filter cars based on search query
  void _filterCars(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCars = _carsList;
      } else {
        _filteredCars = _carsList
            .where((car) =>
                car['model'].toLowerCase().contains(query.toLowerCase()) ||
                car['year'].toLowerCase().contains(query.toLowerCase()) ||
                car['userName'].toLowerCase().contains(query.toLowerCase()) ||
                car['userPhone'].toLowerCase().contains(query.toLowerCase()) ||
                car['userEmail'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // Filter cars that match the search query
      }
    });
  }

  // Show the filter dialog where user can select filters
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filter Cars", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brand Filter Dropdown
              DropdownButton<String>(
                value: _selectedBrand,
                icon: const Icon(Icons.directions_car, color: Colors.white),
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                items: ["All", "X-Trail", "Sentra", "Altima", "rang rovar"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedBrand = newValue!;
                  });
                },
              ),

              // Year Filter Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Start Year:", style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _startYear = picked.year;
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
              child: const Text("Apply", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredCars = _carsList.where((car) {
        // Filter by Brand
        if (_selectedBrand != "All" && car['model'] != _selectedBrand) {
          return false;
        }
        // Filter by Year Range
        if (_startYear != null && int.parse(car['year']) < _startYear!) {
          return false;
        }
        // Apply Search Filter
        String searchText = _searchController.text.toLowerCase();
        if (searchText.isNotEmpty &&
            !car['userName'].toLowerCase().contains(searchText) &&
            !car['model'].toLowerCase().contains(searchText) &&
            !car['year'].toString().contains(searchText)) {
          return false;
        }
        return true;
      }).toList();
      _sortResults();
    });
  }

  // Function to sort the cars based on selected criteria
  void _sortResults() {
    setState(() {
      _filteredCars.sort((a, b) {
        switch (_selectedSort) {
          case "Model (A-Z)":
            return a['model'].compareTo(b['model']);
          case "Model (Z-A)":
            return b['model'].compareTo(a['model']);
          case "Year (Newest First)":
            return int.parse(b['year']).compareTo(int.parse(a['year']));
          case "Year (Oldest First)":
            return int.parse(a['year']).compareTo(int.parse(b['year']));
          case "Owner (A-Z)":
            return a['userName'].compareTo(b['userName']);
          case "Owner (Z-A)":
            return b['userName'].compareTo(a['userName']);
          default:
            return 0;
        }
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();  // Clear search field
      _selectedSort = "Date (Earliest First)";  // Reset sorting to default
      _selectedBrand = "All";  // Reset status filter
      _startYear = null;  // Clear date filter
      _filteredCars = List.from(_carsList);  // Reset the list to include all cars
      _sortResults();  // Reapply the default sorting
    });
  }

  // Show the sorting dialog where user can select sorting order
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sort Cars", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sort options dropdown
              DropdownButton<String>(
                value: _selectedSort,
                icon: const Icon(Icons.sort, color: Colors.white),
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                items: [
                  "Model (A-Z)",
                  "Model (Z-A)",
                  "Year (Newest First)",
                  "Year (Oldest First)",
                  "Owner (A-Z)",
                  "Owner (Z-A)"
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text("Cars List", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E2E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Column(
          children: [
            // Search + Sort + Filter in One Row
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search by user name, phone number, car model, year, and more...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) {
                        _applyFilters();  // Apply the filters when the user types
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
                  // Here is the reset button!
                  TextButton.icon(
                    onPressed: _resetFilters,  // Calls the reset function when pressed
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text("Reset", style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ),
            const SizedBox(height: 16.0),
            // Scrollable Data Table
            Expanded(
              child: Card(
                color: Colors.black,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.black87),
                          dataRowColor: MaterialStateColor.resolveWith((states) => Colors.black54),
                          border: TableBorder.all(width: 1, color: Colors.grey.shade800),
                          columns: const [
                            DataColumn(label: Text('Model', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('User Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Failure Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Failure Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          ],
                          rows: List.generate(_filteredCars.length, (index) {
                            final car = _filteredCars[index];
                            final rowColor = index % 2 == 0 ? Colors.black54 : Colors.black38;

                            return DataRow(
                              color: MaterialStateProperty.resolveWith((states) => rowColor),
                              cells: [
                                DataCell(Text(car['model'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                                DataCell(Text(car['year'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                                DataCell(Text(car['userName'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                                DataCell(Text(car['userPhone'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                                DataCell(Text(car['userEmail'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                                DataCell(Text(car['failureType'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                                DataCell(Text(car['failureDesc'], style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
       ),
    );
  }
}