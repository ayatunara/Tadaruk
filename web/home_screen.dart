import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

// Define Admin Dashboard as a StatefulWidget
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  int _userCount = 0;
  int _appointmentCount = 0;
  int _doneAppointments = 0;
  Map<int, int> _appointmentsPerMonth = {};
  Map<int, int> _failuresPerMonth = {};
  int _dueFailures = 0;
  int _pendingFailures = 0;
  int _notYetAppointments = 0;
  Map<String, int> _failureTypesCount = {}; 

  @override
  void initState() {
    super.initState();
    _fetchUserCount();
    _fetchAppointmentCount();
    _fetchAppointmentData();
    _fetchAppointmentsPerMonth();
    _fetchFailuresPerMonth();
    _fetchFailureTypes(); 
  }

  // Fetch number of users from the 'users' node
  void _fetchUserCount() {
    _database.child('users').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      setState(() {
        _userCount = data != null ? data.length : 0;
      });
    });
  }

  // Fetch number of appointments from the 'car_appointments' node
  void _fetchAppointmentCount() {
    _database.child('car_appointments').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      setState(() {
        _appointmentCount = data != null ? data.length : 0;
      });
    });
  }

  // Fetch appointment data and classify into 'done' or 'not yet' based on the current date
  void _fetchAppointmentData() {
    _database.child('car_appointments').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      int doneCount = 0;
      int notYetCount = 0;

      if (data != null) {
        DateTime now = DateTime.now();
        for (var entry in data.entries) {
          try {
            String dateString = entry.value['date'];
            DateTime appointmentDate = DateTime.parse(dateString);

            if (appointmentDate.isBefore(now)) {
              doneCount++;
            } else {
              notYetCount++;
            }
          } catch (e) {
            debugPrint("❌ خطأ في قراءة التاريخ: $e");
          }
        }
      }

      setState(() {
        _appointmentCount = data?.length ?? 0;
        _doneAppointments = doneCount;
        _notYetAppointments = notYetCount;
      });
    });
  }

  // Fetch appointments per month
  void _fetchAppointmentsPerMonth() {
    _database.child('car_appointments').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        Map<int, int> monthlyCounts = {};
        for (var entry in data.entries) {
          String dateString = entry.value['date'];
          DateTime date = DateTime.parse(dateString);
          int month = date.month;
          monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
        }
        setState(() {
          _appointmentsPerMonth = monthlyCounts;
        });
      }
    });
  }

  // Fetch failures per month
  void _fetchFailuresPerMonth() {
    _database.child('failures').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        Map<int, int> monthlyCounts = {};
        for (var entry in data.entries) {
          String dateString = entry.value['date'];
          DateTime date = DateTime.parse(dateString);
          int month = date.month;
          monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
        }
        setState(() {
          _failuresPerMonth = monthlyCounts;
        });
      }
    });
  }

// Fetch types of failures and count their occurrences
void _fetchFailureTypes() {
  _database.child('failures').onValue.listen((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      Map<String, int> failureCounts = {};
      for (var entry in data.entries) {
        String description = entry.value['description'];

        // Remove the word "Possible" from the description if it exists
        description = description.replaceAll('Possible', '').trim();

        // Add the cleaned description into the map
        failureCounts[description] = (failureCounts[description] ?? 0) + 1;
      }
      setState(() {
        _failureTypesCount = failureCounts;
      });
    }
  });
}


  //Build Pie Chart for appointment status (Done/Not Yet)
  Widget _buildPieChart() {
    return Card(
      color: const Color(0xFF2A2D3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const Text(
              "Status of Appointment",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              width: 100,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 10,
                  sections: [
                    if (_doneAppointments > 0)
                      PieChartSectionData(
                        color: const Color(0xFFF6C6EA),
                        value: _doneAppointments.toDouble(),
                        title: 'Done',
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (_notYetAppointments > 0)
                      PieChartSectionData(
                        color: const Color(0xFF4A7EBB),
                        value: _notYetAppointments.toDouble(),
                        title: 'Not Yet',
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a card displaying an icon, title, and a numeric value
  Widget _buildInfoCard(String title, int value, IconData icon) {
  return Card(
    color: const Color(0xFF2A2D3E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتوى داخل البطاقة
        children: [
          Icon(icon, color: Colors.white70, size: 40),
          const SizedBox(height: 5), // تقليل المسافة هنا
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 35),
          Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

  // Build bar chart for failure types
  Widget _buildFailureTypesChart() {
    return _buildBarChart("Type of Failures", _failureTypesCount);
  }

  // Generic function to build a bar chart with custom data
  Widget _buildBarChart(String title, Map<dynamic, int> data) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: Card(
        color: const Color(0xFF2A2D3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              Expanded(
                child: BarChart(
                  BarChartData(
                    backgroundColor: const Color(0xFF1E1E2E),
                    barGroups: data.entries.map((entry) {
                      return BarChartGroupData(
                        x: data.keys.toList().indexOf(entry.key),
                        barRods: [BarChartRodData(toY: entry.value.toDouble(), color: const Color(0xFFF6C6EA), width: 12)],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < data.length) {
                              return Text(data.keys.elementAt(value.toInt()), style: const TextStyle(fontSize: 10, color: Colors.white70));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawHorizontalLine: true, horizontalInterval: 5),
                    barTouchData: BarTouchData(enabled: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a bar chart for data that is mapped by months
  Widget _buildBarChart2(String title, Map<int, int> data) {
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  return AspectRatio(
    aspectRatio: 1.8,
    child: Card(
      color: const Color(0xFF2A2D3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            Expanded(
              child: BarChart(
                BarChartData(
                  backgroundColor: const Color(0xFF1E1E2E),
                  barGroups: List.generate(12, (index) {
                    int month = index + 1;
                    int count = data[month] ?? 0;
                    return BarChartGroupData(
                      x: month,
                      barRods: [BarChartRodData(toY: count.toDouble(), color: const Color(0xFFF6C6EA), width: 12)],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1 && value <= 12) {
                            return Text(months[value.toInt() - 1], style: const TextStyle(fontSize: 10, color: Colors.white70));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawHorizontalLine: true, horizontalInterval: 5),
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text('Admin Dashboard', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Users', _userCount, Icons.person)),
                Expanded(child: _buildInfoCard('Appointments', _appointmentCount, Icons.calendar_today)),
                Expanded(child: _buildPieChart()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildBarChart2("Failures per Month", _failuresPerMonth)),
                const SizedBox(width: 20),
                Expanded(child: _buildFailureTypesChart()), // build State of Failure
              ],
            ),
          ],
        ),
      ),
    );
  }
}
