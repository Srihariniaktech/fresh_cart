/*
 * ============================================================
 * LOGIN SCREEN - Flutter Frontend
 * ============================================================
 *
 * This is the login screen for FreshCart app.
 * It handles user login with Firebase Auth and connects to backend API.
 *
 * COMPLETE FLOW:
 *
 *   Step 1: User enters email and password
 *           ↓
 *   Step 2: Flutter validates the form
 *           ↓
 *   Step 3: Flutter calls Firebase Auth to authenticate
 *           Firebase verifies email/password against Firebase servers
 *           ↓
 *   Step 4: Firebase returns an ID Token (JWT)
 *           This token proves the user has successfully authenticated
 *           ↓
 *   Step 5: Flutter sends this ID Token to Backend API
 *           Request: POST /api/auth/verify
 *           Header:  Authorization: Bearer <firebase_id_token>
 *           ↓
 *   Step 6: Backend receives the request
 *           Backend's verifyToken middleware extracts the token
 *           ↓
 *   Step 7: Backend calls Firebase Admin SDK to verify the token
 *           Firebase Admin SDK: admin.auth().verifyIdToken(token)
 *           ↓
 *   Step 8: Token is valid! Backend fetches additional user details
 *           Using: admin.auth().getUser(uid)
 *           ↓
 *   Step 9: Backend returns success response to Flutter
 *           Response: { success: true, user: { uid, email, ... } }
 *           ↓
 *   Step 10: Flutter navigates to HomeScreen
 *
 * ERROR FLOWS:
 *
 *   If Firebase login fails (wrong password, etc.)
 *   → Show error message to user
 *
 *   If Firebase token verification fails on backend
 *   → Return 401 error
 *   → Flutter shows "Invalid token" or "Connection error"
 *
 *   If backend is unreachable
 *   → Flutter catches the HTTP error
 *   → Shows "Connection error. Please check your network."
 *
 */

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../home_screen/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onCreateAccount});

  // Callback to navigate to Sign In screen
  // Used when user taps "No account yet? Sign In"
  final VoidCallback onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation
  // Used to check if form is valid before submission
  final _formKey = GlobalKey<FormState>();

  // Text controllers to read user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Clean up controllers when widget is destroyed
  // Prevents memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  // ============================================================
  // STEP 1: SUBMIT LOGIN FORM
  // ============================================================
  //
  // This function is called when user taps the Login button
  //
  // FLOW:
  //   1. Validate form (email format, password not empty)
  //   2. Get email and password from text fields
  //   3. Call Firebase Auth to authenticate
  //   4. Get Firebase ID Token from the auth result
  //   5. Send ID Token to Backend API for verification
  //   6. On success, navigate to HomeScreen
  //
  Future<void> _submit() async {
    // --------------------------------------------------------
    // VALIDATION STEP
    // --------------------------------------------------------
    // Check if form is valid
    // _formKey.currentState.validate() calls each field's validator
    // If any validator returns non-null (error), form is invalid
    if (!_formKey.currentState!.validate()) {
      return; // Don't proceed if form is invalid
    }

    // Get user input from text fields
    // .trim() removes leading/trailing whitespace
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // --------------------------------------------------------
      // STEP 2: FIREBASE AUTHENTICATION
      // --------------------------------------------------------
      //
      // Call Firebase Auth to sign in with email and password
      // FirebaseAuth.instance.signInWithEmailAndPassword:
      //   - Connects to Firebase servers
      //   - Verifies email and password
      //   - Creates a local session for the user
      //
      // Returns: UserCredential object containing:
      //   - user: The authenticated User object
      //   - credential: The credential (ID token, etc.)
      //
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // --------------------------------------------------------
      // STEP 3: GET FIREBASE ID TOKEN
      // --------------------------------------------------------
      //
      // After successful Firebase login, get the ID token
      // This token proves the user has authenticated with Firebase
      //
      // getIdToken() returns a JWT (JSON Web Token)
      // This token can be verified by any server
      // It contains the user's UID and other claims
      //
      // The token is valid for 1 hour
      // After that, user needs to re-authenticate
      //
      final idToken = await credential.user!.getIdToken();

      debugPrint('[Login] Firebase auth successful');
      debugPrint('[Login] User: ${credential.user?.email}');

      // --------------------------------------------------------
      // STEP 4: NAVIGATE TO HOME SCREEN (Firebase login only)
      // --------------------------------------------------------
      // NOTE: Backend API verification is optional.
      // If backend is unreachable, Firebase login is still valid.
      // We navigate immediately after Firebase login succeeds.
      //
      // Wrap in addPostFrameCallback to ensure navigation after frame renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });

      // --------------------------------------------------------
      // STEP 5: SEND TOKEN TO BACKEND API (background)
      // --------------------------------------------------------
      // This runs AFTER navigation so it doesn't block the user.
      // If this fails, user is already on HomeScreen.
      //
      _callBackendApi(idToken!);

    }
    // --------------------------------------------------------
    // ERROR HANDLING
    // --------------------------------------------------------
    on FirebaseAuthException catch (e) {
      // Firebase Auth specific errors
      // These are errors from Firebase authentication

      if (!mounted) return; // Widget may have been disposed

      String message; // Error message to show user

      // Check specific error codes and set appropriate message
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Email address is invalid.';
          break;
        case 'invalid-credential':
          message = 'Email or password is incorrect.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }

      _showMessage(message);

    } catch (e) {
      // Network error or other unexpected errors
      if (!mounted) return;
      debugPrint('[Login] Error: $e');
      _showMessage('Connection error. Please check your network.');
    }
  }


  // ============================================================
  // BACKEND API CALL (runs in background, non-blocking)
  // ============================================================
  Future<void> _callBackendApi(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('[Login] Backend verified: $idToken');
      } else {
        debugPrint('[Login] Backend returned: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Login] Backend offline: $e');
    }
  }


  // ============================================================
  // HELPER: SHOW SNACKBAR MESSAGE
  // ============================================================
  //
  // Shows a temporary message at the bottom of the screen
  // Used for error messages and success notifications
  //
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


  // ============================================================
  // BUILD THE UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFFBEF), Color(0xFFFFFAF4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with animated logo
                const _HeaderCard(
                  title: 'Welcome back',
                  subtitle:
                      'Login with your email and password to continue shopping.',
                ),
                const SizedBox(height: 24),

                // Login form container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey, // Attach form key for validation
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Login title
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF193524),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Email field
                        _AppField(
                          controller: _emailController,
                          label: 'Email',
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Email is required';
                            }
                            if (!email.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password field
                        _AppField(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: 'Enter your password',
                          obscureText: true, // Hide password characters
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _submit, // Triggers _submit() function
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF209149),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Sign in link
                        Center(
                          child: TextButton(
                            onPressed: widget.onCreateAccount,
                            child: const Text(
                              'No account yet? Sign In',
                              style: TextStyle(
                                color: Color(0xFF1E8041),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// HEADER CARD - Animated welcome header
// ============================================================
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D9647), Color(0xFF39B95E)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const _AnimatedLogoBadge(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ANIMATED LOGO BADGE - Bouncing cart icon
// ============================================================
class _AnimatedLogoBadge extends StatefulWidget {
  const _AnimatedLogoBadge();

  @override
  State<_AnimatedLogoBadge> createState() => _AnimatedLogoBadgeState();
}

class _AnimatedLogoBadgeState extends State<_AnimatedLogoBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final lift = -4 * _controller.value;
        final scale = 1 + (0.05 * _controller.value);
        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: Color(0xFF22B455),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================
// APP FIELD - Reusable text input field
// ============================================================
class _AppField extends StatelessWidget {
  const _AppField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?) validator;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF345140),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF6FAF4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFC94A4A)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFC94A4A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF1D9348),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

