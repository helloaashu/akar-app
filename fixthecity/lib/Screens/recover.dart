import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RecoverPage extends StatefulWidget {
  const RecoverPage({super.key});

  @override
  _RecoverPageState createState() => _RecoverPageState();
}

class _RecoverPageState extends State<RecoverPage> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> sendPasswordResetEmail(String email, BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      // Check if the email exists in the Firestore users collection
      var users = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (users.docs.isEmpty) {
        // No user found with this email
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No user found for that email'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade600,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Main content
              Column(
                children: [
                  // Custom app bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Icon with animation
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 1000),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          height: 120,
                                          width: 120,
                                          margin: const EdgeInsets.only(bottom: 32),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.3),
                                                Colors.white.withOpacity(0.1),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.deepPurple.shade900.withOpacity(0.3),
                                                blurRadius: 30,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.lock_reset_rounded,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Title
                                  const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 32.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Don\'t worry! Enter your email below and we\'ll send you a reset link.',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 48),
                                  // Email field with glass morphism effect
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white.withOpacity(0.15),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: emailController,
                                      style: const TextStyle(color: Colors.white),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                        if (!emailRegex.hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                        prefixIcon: Container(
                                          padding: const EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.email_outlined,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 20,
                                        ),
                                        errorStyle: const TextStyle(
                                          color: Colors.orangeAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Submit button
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Color(0xFFF5F5F5),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepPurple.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                        if (formKey.currentState!.validate()) {
                                          sendPasswordResetEmail(
                                              emailController.text.trim(), context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.deepPurple,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Text(
                                        'Send Reset Link',
                                        style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Divider with text
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Back to login button
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, "/login");
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_back,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Back to Login',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}