// Import the material design package which contains core Flutter widgets
import 'package:flutter/material.dart';
import 'menu_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth package
//This file hosts the Login Page of the app

// Define a StatefulWidget class named LoginPage
// StatefulWidget is used when the widget needs to maintain state that can change
class LoginPage extends StatefulWidget {
  // Constructor with optional named parameter 'key'
  // 'super.key' passes the key to the parent class
  const LoginPage({super.key});

  // Create the mutable state for this widget
  // This is required for all StatefulWidgets
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// The actual state class for LoginPage
// The underscore '_' makes this class private to this file
class _LoginPageState extends State<LoginPage> {
  // TextEditingController manages the text input state
  // One controller per text field is needed
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // GlobalKey used to identify and validate the Form widget
  final _formKey = GlobalKey<FormState>();

  // dispose() is called when the widget is removed from the widget tree
  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    // This prevents memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Method to handle the login button press
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Attempt to sign in with email and password
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Verify the user is signed in
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('User signed in: ${user.email}');
        }

        // Only navigate if login was successful and widget is still mounted
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MenuPage(currentUserID: user!.uid)),
          );
        }
      } on FirebaseAuthException catch (e) {
        // Handle specific Firebase errors
        String errorMessage;
        switch (e.code) {
          case 'invalid-credential':
            errorMessage = 'User does not exist or incorrect password';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }
        
        // Print the error code for debugging
        print('Firebase Auth Error Code: ${e.code}');
        
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Method to handle forgot password
  void _handleForgotPassword() async {
    // Show dialog to enter email
    final String? email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          initialValue: _emailController.text,
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _emailController.text),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    // Check if email was provided
    if (email != null && email.isNotEmpty && mounted) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent! Check your email.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        title: const Text('Login'),
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
              // Email input field
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
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;  // null means validation passed
                },
              ),
              // Add vertical space between fields
              const SizedBox(height: 16),
              
              // Password input field
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
              
              // Login button
              ElevatedButton(
                onPressed: _handleLogin,  // Assign the login handler
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),  // Make button full width
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              
              // Forgot password button
              TextButton(
                onPressed: _handleForgotPassword,  // Assign the forgot password handler
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
