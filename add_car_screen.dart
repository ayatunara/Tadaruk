import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddCarScreen extends StatelessWidget {
  const AddCarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference _database = FirebaseDatabase.instance.ref();
    final TextEditingController _carIDController = TextEditingController();
    final TextEditingController _modelController = TextEditingController();
    final TextEditingController _yearController = TextEditingController();
    final TextEditingController _userNameController = TextEditingController();
    final TextEditingController _userAgeController = TextEditingController();
    final TextEditingController _userPhoneController = TextEditingController(); // phone number field
    final TextEditingController _userEmailController = TextEditingController(); // email field

    // Function to add both car and user to the database
    void _addCarAndUser() {
      final String carID = _carIDController.text.trim();
      final String model = _modelController.text.trim();
      final String year = _yearController.text.trim();
      final String userName = _userNameController.text.trim();
      final String userAge = _userAgeController.text.trim();
      final String userPhone = _userPhoneController.text.trim();
      final String userEmail = _userEmailController.text.trim();

      if (carID.isNotEmpty &&
          model.isNotEmpty &&
          year.isNotEmpty &&
          userName.isNotEmpty &&
          userAge.isNotEmpty &&
          userPhone.isNotEmpty &&
          userEmail.isNotEmpty) {
		// Create a new user entry and get the generated key
        final userRef = _database.child('users').push();
        final userID = userRef.key;

        userRef.set({
          'name': userName,
          'age': userAge,
          'phone': userPhone, // Save the phone number
          'email': userEmail, 
        }).then((_) {
		  // After adding the user, add the car with reference to userID
          _database.child('cars').push().set({
            'carID': carID,
            'model': model,
            'year': year,
            'userID': userID,
          }).then((_) {
		    // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Car and User added successfully!')),
            );
			// Clear all text fields
            _carIDController.clear();
            _modelController.clear();
            _yearController.clear();
            _userNameController.clear();
            _userAgeController.clear();
            _userPhoneController.clear();
            _userEmailController.clear();
          }).catchError((error) {
		    // Show error if adding car fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding car: $error')),
            );
          });
        }).catchError((error) {
		  // Show error if adding user fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding user: $error')),
          );
        });
      } else {
	    // Show warning if any field is empty
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields!')),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInputField('Car ID', _carIDController),
          const SizedBox(height: 10),
          _buildInputField('Model', _modelController),
          const SizedBox(height: 10),
          _buildInputField('Year', _yearController),
          const SizedBox(height: 10),
          _buildInputField('User Name', _userNameController),
          const SizedBox(height: 10),
          _buildInputField('User Age', _userAgeController),
          const SizedBox(height: 10),
          _buildInputField('User Phone', _userPhoneController), 
          const SizedBox(height: 10),
          _buildInputField('User Email', _userEmailController), 
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addCarAndUser,
            child: const Text('Add Car and User'),
          ),
        ],
      ),
    );
  }

  // Helper widget to create input fields
  Widget _buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[800],
      ),
    );
  }
}
