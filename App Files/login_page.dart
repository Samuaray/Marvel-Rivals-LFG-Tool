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

  bool _isLoading = false; // Add loading state

  // dispose() is called when the widget is removed from the widget tree
  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    // This prevents memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Updated login handler
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // This will automatically persist the auth state
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = userCredential.user;
      if (user != null) {
        // Use pushAndRemoveUntil to clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MenuPage(currentUserID: user.uid),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      //print('Unexpected error: $e'); // Debug print
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Hide loading state
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'An error occurred during login';
    }
  }

  // Method to handle forgot password
  void _handleForgotPassword() async {
    final emailController = TextEditingController(text: _emailController.text);
    
    final String? email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextFormField(
          controller: emailController,  // Use the controller instead of initialValue
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    // Add debug prints
    //print('Attempting password reset for email: $email');

    if (email != null && email.isNotEmpty && mounted) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
       // print('Password reset email sent successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent! Check your email.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        //print('Password reset error: ${e.code} - ${e.message}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getPasswordResetErrorMessage(e.code)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Add specific error messages for password reset
  String _getPasswordResetErrorMessage(String code) {
    switch (code) {
      case 'auth/invalid-email':
        return 'Invalid email address format';
      case 'auth/user-not-found':
        return 'No account exists with this email';
      case 'auth/too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Error sending password reset email';
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
      body: Stack(
        children: [
          Padding(
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
                    onPressed: _isLoading ? null : _handleLogin,  // Assign the login handler
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),  // Make button full width
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Login'),
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
        ],
      ),
    );
  }
}
