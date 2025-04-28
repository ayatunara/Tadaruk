import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'email_verification_page.dart';
import 'login_page.dart';
import 'package:flutter/gestures.dart';


// Stateful widget for the Sign Up Page
class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Firebase Auth and Realtime Database references
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _carsRef = FirebaseDatabase.instance.ref("cars");
  // Text controllers for form fields
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // Dropdown values
  String? selectedCarModel;
  String? selectedCarYear;

  // Predefined car model and year lists
  final List<String> carModels = ['X-Trail', 'Altima', 'Sentra'];
  final List<String> carYears = ['2020', '2021', '2022'];

  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

void _signUp() async {
  setState(() {
    _isLoading = true;
  });

// Validate each required field and show warning if missing
if (_nameController.text.isEmpty) {
  _showWarningMessage("Name is required");
  setState(() {
    _isLoading = false;
  });
  return;
}

if (_emailController.text.isEmpty) {
  _showWarningMessage("Email is required");
  setState(() {
    _isLoading = false;
  });
  return;
}

if (_passwordController.text.isEmpty) {
  _showWarningMessage("Password is required");
  setState(() {
    _isLoading = false;
  });
  return;
}

if (_confirmPasswordController.text.isEmpty) {
  _showWarningMessage("Confirm Password is required");
  setState(() {
    _isLoading = false;
  });
  return;
}

if (_phoneNumberController.text.isEmpty) {
  _showWarningMessage("Phone number is required");
  setState(() {
    _isLoading = false;
  });
  return;
}

if (_passwordController.text != _confirmPasswordController.text) {
  _showWarningMessage("Passwords do not match");
  setState(() {
    _isLoading = false;
  });
  return;
}


  try {
    // Create user using Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    User? user = userCredential.user;
    String userId = user!.uid;

    // Send email verification
    await user.sendEmailVerification();

    // Save user details in Firebase Realtime Database
    await _usersRef.child(userId).set({
      'id': userId,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneNumberController.text.trim(),
      'verified': false,
    });

    // Save car details associated with the user
    String carId = _carsRef.push().key!;
    await _carsRef.child(carId).set({
      'id': carId,
      'user_id': userId,
'car_model': _carModelController.text.trim(),
'car_year': _carYearController.text.trim(),

    });
    // Show success message and navigate to verification page
    _showSuccessMessage("The verification email has been sent! Please confirm your email.");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailVerificationPage(),
      ),
    );
  } catch (e) {
    _showErrorMessage("Registration failed: $e");
  }

  setState(() {
    _isLoading = false;
  });
}

// Function to show warning messages in a snackbar
void _showWarningMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning, color: Colors.redAccent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

// Function to show success messages in a snackbar
void _showSuccessMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Color.fromARGB(255, 4, 87, 14), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 84, 161, 96),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

// Function to show error messages in a snackbar
void _showErrorMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.redAccent, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
  // UI build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.155,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF3A5A98),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(75)),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 15, left: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
		  // Main form container
          Padding(
            padding: const EdgeInsets.only(top: 140),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height - 140,
              decoration: const BoxDecoration(
                color: Color(0xFF001A72),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Create New Account",
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Already Registered? ",
                          style: const TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Log in here!",
                              style: const TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginPage()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
					// Form fields
                    _buildTextField("NAME", _nameController),
                    _buildTextField("EMAIL", _emailController, inputType: TextInputType.emailAddress),
                    _buildTextField("PASSWORD", _passwordController, obscureText: true),
                    _buildTextField("CONFIRM PASSWORD", _confirmPasswordController, obscureText: true),
                    _buildTextField("PHONE NUMBER", _phoneNumberController, inputType: TextInputType.phone),
                    const SizedBox(height: 10),
// Car model and year input
Row(
  children: [
    Expanded(
      child: _buildTextField("CAR MODEL", _carModelController),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _buildTextField("CAR YEAR", _carYearController, inputType: TextInputType.number),
    ),
  ],
),

                    const SizedBox(height: 30),
					// Sign Up button or loading indicator
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
// Reusable function to build a styled text field
Widget _buildTextField(String label, TextEditingController controller, {
  bool obscureText = false,
  TextInputType inputType = TextInputType.text,
}) {
  bool isPasswordField = label == "PASSWORD";
  bool isConfirmPasswordField = label == "CONFIRM PASSWORD";

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *', // Add red asterisk to indicate required field
          style: const TextStyle(
            color: Colors.white70, 
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: (isPasswordField && !_isPasswordVisible) || (isConfirmPasswordField && !_isConfirmPasswordVisible),
          keyboardType: inputType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: (isPasswordField || isConfirmPasswordField)
                ? IconButton(
                    icon: Icon(
                      (isPasswordField ? _isPasswordVisible : _isConfirmPasswordVisible)
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isPasswordField) {
                          _isPasswordVisible = !_isPasswordVisible;
                        } else {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        }
                      });
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}


  //drop down field widget
  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: Colors.blueGrey[700],
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
