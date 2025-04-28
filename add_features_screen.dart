import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddFeaturesScreen extends StatefulWidget {
  const AddFeaturesScreen({super.key});

  @override
  _AddFeaturesScreenState createState() => _AddFeaturesScreenState();
}

class _AddFeaturesScreenState extends State<AddFeaturesScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String? _selectedCarId;
  String? _selectedModel;
  Map<String, dynamic> _cars = {};
  bool _isProcessing = false;

  final String batteryApiUrl = "http://192.168.56.1:5000/predict";
  final String engineApiUrl = "http://192.168.56.1:5001/predict_engine";

  // Define failure dictionaries for both battery and engine
  final Map<int, String> engineFailures = {
    0: 'Normal',
    1: 'Possible Lubrication System Failure',
    2: 'Possible Cooling System Failure'
  };

  final Map<int, String> batteryFailures = {
    0: 'Normal',
    1: 'Possible Degradation',
    2: 'Possible Thermal Runaway'
  };

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

  /// Send the features to the API for prediction
  Future<void> sendPredictionRequest() async {
    if (_selectedCarId == null || _selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار السيارة ونوع المودل قبل التنبؤ!')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Fetch `SensorData`
      DatabaseEvent sensorEvent = await _database.child('SensorData').child(_selectedCarId!).once();
      Map<String, dynamic> sensorData = sensorEvent.snapshot.value != null
          ? Map<String, dynamic>.from(sensorEvent.snapshot.value as Map)
          : {};

      if (sensorData.isEmpty) {
        throw '❌ لا توجد بيانات مستشعرات لهذه السيارة.';
      }

      // Fetch the last 9 records from `HistoricalRecords`
      DatabaseEvent historicalEvent = await _database.child('HistoricalRecords').child(_selectedCarId!).once();
      Map<String, dynamic> historicalData = historicalEvent.snapshot.value != null
          ? Map<String, dynamic>.from(historicalEvent.snapshot.value as Map)
          : {};

      if (historicalData.isEmpty || historicalData.length < 9) {
        throw '❌ لا توجد بيانات تاريخية كافية (تحتاج على الأقل 9 سجلات).';
      }

      // Sort the records from oldest to newest
      List<String> recordKeys = historicalData.keys.toList();
      recordKeys.sort();

      List<double> batteryFeatures = [];
      List<double> engineFeatures = [];

      // Build the features based on the selected model type
      for (int i = 0; i < 9; i++) {
        String recordId = recordKeys[i];
        Map<String, dynamic> record = Map<String, dynamic>.from(historicalData[recordId]);

        // Add battery features
        batteryFeatures.add(double.parse(record['BatteryVoltage']));
        batteryFeatures.add(double.parse(record['BatteryTemperature']));
        batteryFeatures.add(double.parse(record['ChargeLevel']));
        batteryFeatures.add(double.parse(record['DischargeRate']));

        // Add engine features
        engineFeatures.add(double.parse(record['Engine_rpm']));
        engineFeatures.add(double.parse(record['Lub_oil_pressure']));
        engineFeatures.add(double.parse(record['Fuel_pressure']));
        engineFeatures.add(double.parse(record['Coolant_pressure']));
        engineFeatures.add(double.parse(record['Coolant_temp']));
      }

      // Add `SensorData` to the features list
      batteryFeatures.add(double.parse(sensorData['BatteryVoltage']));
      batteryFeatures.add(double.parse(sensorData['BatteryTemperature']));
      batteryFeatures.add(double.parse(sensorData['ChargeLevel']));
      batteryFeatures.add(double.parse(sensorData['DischargeRate']));

      engineFeatures.add(double.parse(sensorData['Engine_rpm']));
      engineFeatures.add(double.parse(sensorData['Lub_oil_pressure']));
      engineFeatures.add(double.parse(sensorData['Fuel_pressure']));
      engineFeatures.add(double.parse(sensorData['Coolant_pressure']));
      engineFeatures.add(double.parse(sensorData['Coolant_temp']));

      // Send the collected data to the appropriate API
      String apiUrl = _selectedModel == 'Battery' ? batteryApiUrl : engineApiUrl;
      List<double> featuresToSend = _selectedModel == 'Battery' ? batteryFeatures : engineFeatures;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": featuresToSend}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int prediction = data['prediction'];

        // Save the result only if the prediction is not "Normal"
        if (prediction != 0) {
          String failureDescription = _selectedModel == 'Battery'
              ? batteryFailures[prediction] ?? 'Unknown Battery Issue'
              : engineFailures[prediction] ?? 'Unknown Engine Issue';

          await _database.child('failures').push().set({
            'carId': _selectedCarId,
            'date': DateTime.now().toIso8601String(),
            'type': _selectedModel,
            'description': failureDescription,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ تم التنبؤ بوجود مشكلة: $failureDescription')),
          );
        }
      } else {
        print("❌ خطأ في التنبؤ: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 خطأ أثناء التنبؤ: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنبؤ بحالة السيارة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown to select the car
            DropdownButton<String>(
              value: _selectedCarId,
              hint: const Text('اختر سيارة'),
              isExpanded: true,
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
            const SizedBox(height: 20),

            // Dropdown to select model type (Battery or Engine)
            DropdownButton<String>(
              value: _selectedModel,
              hint: const Text('اختر نوع المودل'),
              isExpanded: true,
              items: ['Battery', 'Engine'].map((model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedModel = value;
                });
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isProcessing ? null : sendPredictionRequest,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('تنفيذ التنبؤ'),
            ),
          ],
        ),
      ),
    );
  }
}
