// Import the material design package which contains core Flutter widgets
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, Timestamp, FieldValue;
import 'menu_page.dart';

//This file hosts the Registration Page of the app

// Define a StatefulWidget class named RegisterPage
// StatefulWidget is used when the widget needs to maintain state that can change
class RegisterPage extends StatefulWidget {
  // Constructor with optional named parameter 'key'
  // 'super.key' passes the key to the parent class
  const RegisterPage({super.key});

  // Create the mutable state for this widget
  // This is required for all StatefulWidgets
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// The actual state class for RegisterPage
// The underscore '_' makes this class private to this file
class _RegisterPageState extends State<RegisterPage> {
  // TextEditingController manages the text input state
  // One controller per text field is needed
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  final _userIDController = TextEditingController();
  final _platformController = TextEditingController();
  // GlobalKey used to identify and validate the Form widget
  final _formKey = GlobalKey<FormState>();

  // dispose() is called when the widget is removed from the widget tree
  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    // This prevents memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    _userIDController.dispose();
    super.dispose();
  }

  // Method to handle the registration button press
  void _handleRegistraton() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Create the user document in Firestore with matching field names
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'Username': _userIDController.text.trim(),  // Changed from 'UserName'
          'platform': _platformController.text.trim(), // Changed from 'Platform'
          'email': userCredential.user!.email,        // Changed from 'UserEmail'
          'hasJoinedPost': false,                     // Changed from 'PostJoined?'
          'joinedPostAuthor': null,                   // Added to track joined post
          'createdAt': FieldValue.serverTimestamp(),  // Added timestamp
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MenuPage(currentUserID: userCredential.user!.uid)),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase errors
        String errorMessage = 'Registration failed';
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'An account already exists for that email.';
        }
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        // Handle other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration error: $e')),
        );
      }
    }
  }

  // Build method defines the widget's UI
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic app structure
    return Scaffold(
      // AppBar is the top bar of the app
      appBar: AppBar(
        title: const Text('Register'),
      ),
      // Body contains the main content
      body: Padding(
        // Add 16 pixels of padding on all sides
        padding: const EdgeInsets.all(16.0),
        // Form widget to handle form validation
        child: Form(
          key: _formKey,  // Assign the form key for validation
          // Column arranges children vertically
          child: Column(
            // Center the form in the available vertical space
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Email Input Field
              TextFormField(
                controller: _emailController,  // Assign the controller
                decoration: const InputDecoration(
                  labelText: 'Email',  // Label shown above/in the field
                  border: OutlineInputBorder(),  // Outlined border style
                ),
                keyboardType: TextInputType.emailAddress,  // Shows email keyboard on mobile
                // Validation function
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@') | !value.contains('.')) { // Check for valid email format
                    return 'Please enter a valid email';
                  }
                  return null;  // null means validation passed
                },
              ),
              // Add vertical space between fields
              const SizedBox(height: 16),
              
              //Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,  // Hides the password text
                // Password validation
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              //Confirm Password Field
              TextFormField(
                controller: _confirmpasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confrm Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,  // Hides the password text
                // Password validation
                validator: (value) {
                  if (value == null || value.isEmpty) {
                      return 'Please Confrm your password';
                  }
                  if (value != _passwordController.text) { //checks if the passwords match
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              //UserID Field
              TextFormField(
                controller: _userIDController,
                decoration: const InputDecoration(
                  labelText: 'In-Game Username',
                  border: OutlineInputBorder(),
                ),
                // Remove obscureText: true since this isn't a password
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your in-Game Username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

               //Platform Field
              TextFormField(
                controller: _platformController,
                decoration: const InputDecoration(
                  labelText: 'Platform (PC or Console)',
                  border: OutlineInputBorder(),
                ),
                // Remove obscureText: true since this isn't a password
                validator: (value) {
                  if (value == null || value != 'PC' && value != 'Console') {
                    return 'Please enter PC or Console';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Registration Button
              ElevatedButton(
                onPressed: _handleRegistraton,  // Assign the login handler
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),  // Make button full width
                ),
                child: const Text('Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
