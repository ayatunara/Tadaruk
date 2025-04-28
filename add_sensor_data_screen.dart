import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddSensorDataScreen extends StatefulWidget {
  const AddSensorDataScreen({super.key});

  @override
  _AddSensorDataScreenState createState() => _AddSensorDataScreenState();
}

class _AddSensorDataScreenState extends State<AddSensorDataScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String? _selectedCarId;
  Map<String, dynamic> _cars = {};
  final List<TextEditingController> _controllers = List.generate(9, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  /// Fetch the list of cars from Firebase
  void _fetchCars() async {
    DatabaseEvent event = await _database.child('cars').once();
    if (event.snapshot.value != null) {
      setState(() {
        _cars = Map<String, dynamic>.from(event.snapshot.value as Map);
      });
    }
  }

  /// Save new sensor data after moving old data to `HistoricalRecords`
  void _saveSensorData() async {
    if (_selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ الرجاء اختيار سيارة قبل الحفظ!')),
      );
      return;
    }

    DatabaseReference sensorDataRef = _database.child('SensorData').child(_selectedCarId!);
    DatabaseReference historicalRecordsRef = _database.child('HistoricalRecords').child(_selectedCarId!);

    // Move old sensor data to `HistoricalRecords` before overwriting
    DataSnapshot snapshot = (await sensorDataRef.get()) as DataSnapshot;
    if (snapshot.exists) {
      await historicalRecordsRef.push().set(snapshot.value);
    }

    // Prepare new sensor data
    Map<String, dynamic> newSensorData = {
      "Engine_rpm": _controllers[0].text,
      "Lub_oil_pressure": _controllers[1].text,
      "Fuel_pressure": _controllers[2].text,
      "Coolant_pressure": _controllers[3].text,
      "Coolant_temp": _controllers[4].text,
      "BatteryVoltage": _controllers[5].text,
      "BatteryTemperature": _controllers[6].text,
      "ChargeLevel": _controllers[7].text,
      "DischargeRate": _controllers[8].text,
    };

    // Save new sensor data under `SensorData`
    await sensorDataRef.set(newSensorData);

    // Clear all input fields after saving
    for (var controller in _controllers) {
      controller.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم تحديث بيانات المستشعر ونقل القديم إلى `HistoricalRecords`!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة بيانات المستشعر', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black87, // Professional dark color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car selection section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black54, 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚗 اختر السيارة:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedCarId,
                    hint: const Text('اختر السيارة', style: TextStyle(color: Colors.white)),
                    dropdownColor: Colors.black87, 
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _cars.entries.map((entry) {
                      final carData = entry.value;
                      return DropdownMenuItem<String>(
                        value: carData['id'],
                        child: Text('${carData['car_model']} - ${carData['car_year']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCarId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sensor data input card
            Expanded(
              child: Card(
                color: Colors.black54, // consistent dark theme
                elevation: 6, // light shadow
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      const Text(
                        '🔢 إدخال بيانات المستشعر:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Divider(color: Colors.grey),
                      _buildInputField('⚙️ Engine RPM', _controllers[0], Icons.speed),
                      _buildInputField('🛢️ Lub Oil Pressure', _controllers[1], Icons.oil_barrel),
                      _buildInputField('⛽ Fuel Pressure', _controllers[2], Icons.local_gas_station),
                      _buildInputField('🌡️ Coolant Pressure', _controllers[3], Icons.thermostat),
                      _buildInputField('🔥 Coolant Temp', _controllers[4], Icons.whatshot),
                      _buildInputField('🔋 Battery Voltage', _controllers[5], Icons.battery_charging_full),
                      _buildInputField('🌡️ Battery Temperature', _controllers[6], Icons.device_thermostat),
                      _buildInputField('⚡ Charge Level', _controllers[7], Icons.flash_on),
                      _buildInputField('🔻 Discharge Rate', _controllers[8], Icons.arrow_downward),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _saveSensorData,
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ البيانات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ **تصميم `TextField` احترافي مع أيقونات**
  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.black87, // ✅ لون داكن للحقول
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
