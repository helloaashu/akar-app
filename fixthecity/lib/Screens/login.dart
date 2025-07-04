import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../userpages/notification_service.dart';
import '../userpages/userProfile/firebaseApi.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  bool _obscureText = true;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _floatingController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    });

    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _floatingController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> saveAuthState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  var formKey = GlobalKey<FormState>();

  // text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future signIn() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.withOpacity(0.3),
                  Colors.purple.withOpacity(0.3),
                ],
              ),
            ),
            child: const Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Signing you in...',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      final userId = userCredential.user?.uid;

      if (userId != null) {
        await saveAuthState(userId);
        Fluttertoast.showToast(
          msg: "Login Successfully",
          backgroundColor: Colors.deepPurple,
          textColor: Colors.white,
        );
        Navigator.of(context).pop();
        Navigator.pushReplacementNamed(context, "/UserPages");

        await PushNotifications.init();
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();

      String errorMessage = '';
      Color errorColor = Colors.red;

      if (e.code == 'user-not-found') {
        errorMessage = "User not found for that email";
        errorColor = Colors.orange;
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided";
        errorColor = Colors.red;
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted";
        errorColor = Colors.orange;
      } else if (e.code == 'quota-exceeded') {
        errorMessage = "Exceeded quota for verifying passwords";
        errorColor = Colors.orange;
      } else {
        errorMessage = 'Error: ${e.message}';
        errorColor = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      emailController.clear();
      passwordController.clear();
    }
  }

  // Special regex expression for email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // For Password validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    } else if (!RegExp(r'^(?=.*?[A-Z])').hasMatch(value)) {
      return 'Password must have at least one uppercase letter';
    } else if (!RegExp(r'^(?=.*?[a-z])').hasMatch(value)) {
      return 'Password must have at least one lowercase letter';
    } else if (!RegExp(r'^(?=.*?[0-9])').hasMatch(value)) {
      return 'Password must have at least one digit';
    } else if (!RegExp(r'^(?=.*?[!@#$&*~])').hasMatch(value)) {
      return 'Password must have at least one special character';
    }
    return null;
  }

  Future<bool> showExitPopup() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Exit App',
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ],
            ),
            content: const Text('Are you sure you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await showExitPopup();
        if (shouldExit) {
          SystemNavigator.pop();
          return true;
        } else {
          return false;
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade300,
                Colors.deepPurple.shade600,
                Colors.purple.shade800,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      elevation: 20,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.purple.shade50,
                            ],
                          ),
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated Logo/Illustration
                              AnimatedBuilder(
                                animation: _floatingAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatingAnimation.value),
                                    child: ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.deepPurple.shade300,
                                              Colors.purple.shade600,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.smart_toy_outlined,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // App Title with Animation
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Colors.deepPurple,
                                    Colors.purple.shade600,
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Smart Community',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const Text(
                                'AI-Powered Issue Resolution',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Connect. Report. Resolve!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 32),

                              // Email Field with Animation
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 600),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 50 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller: emailController,
                                          validator: validateEmail,
                                          decoration: InputDecoration(
                                            labelText: 'Email Address',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.deepPurple.shade300,
                                                    Colors.purple.shade600,
                                                  ],
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.email_outlined,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.deepPurple,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.red.shade300,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password Field with Animation
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 800),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 50 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller: passwordController,
                                          validator: validatePassword,
                                          obscureText: _obscureText,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.deepPurple.shade300,
                                                    Colors.purple.shade600,
                                                  ],
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.lock_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureText
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                color: Colors.deepPurple,
                                              ),
                                              onPressed:
                                                  _togglePasswordVisibility,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.deepPurple,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.red.shade300,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, "/recover");
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Animated Sign In Button
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      width: double.infinity,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.deepPurple,
                                            Colors.purple.shade600,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurple
                                                .withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (formKey.currentState!
                                              .validate()) {
                                            HapticFeedback.lightImpact();
                                            signIn();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                        ),
                                        child: const Text(
                                          'SIGN IN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // OR Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Social Login Buttons
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1200),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: Column(
                                        children: [
                                          // Google Sign In
                                          Container(
                                            width: double.infinity,
                                            height: 55,
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),

                                            child: ElevatedButton(
                                              onPressed: () async {
                                                HapticFeedback.lightImpact();

                                                try {
                                                  final GoogleSignInAccount?
                                                      googleUser =
                                                      await GoogleSignIn()
                                                          .signIn();
                                                  if (googleUser == null) {
                                                    // User canceled the sign-in
                                                    return;
                                                  }

                                                  final GoogleSignInAuthentication
                                                      googleAuth =
                                                      await googleUser
                                                          .authentication;

                                                  final OAuthCredential
                                                      credential =
                                                      GoogleAuthProvider
                                                          .credential(
                                                    accessToken:
                                                        googleAuth.accessToken,
                                                    idToken: googleAuth.idToken,
                                                  );

                                                  final userCredential =
                                                      await FirebaseAuth
                                                          .instance
                                                          .signInWithCredential(
                                                              credential);
                                                  // ✅ Navigation to Home Page
                                                  Navigator
                                                      .pushReplacementNamed(
                                                          context,
                                                          "/UserPages");

                                                  // ✅ Success Snackbar
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: const [
                                                          Icon(
                                                              Icons
                                                                  .check_circle_outline,
                                                              color:
                                                                  Colors.white),
                                                          SizedBox(width: 8),
                                                          Text(
                                                              'Signed in as Google user!'),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  // ❌ Error Snackbar
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: const [
                                                          Icon(
                                                              Icons
                                                                  .error_outline,
                                                              color:
                                                                  Colors.white),
                                                          SizedBox(width: 8),
                                                          Text(
                                                              'Google Sign-In failed.'),
                                                        ],
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                  );
                                                  print(
                                                      "Google Sign-In error: $e");
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor:
                                                    Colors.grey.shade700,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      color: Colors.white,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: Image.network(
                                                        'https://developers.google.com/identity/images/g-logo.png',
                                                        width: 24,
                                                        height: 24,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Container(
                                                            width: 24,
                                                            height: 24,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.red,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: const Icon(
                                                              Icons
                                                                  .g_mobiledata,
                                                              color:
                                                                  Colors.white,
                                                              size: 16,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'Google',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Facebook Sign In
                                          Container(
                                            width: double.infinity,
                                            height: 55,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF1877F2),
                                                  Color(0xFF42A5F5),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Color(0xFF1877F2)
                                                      .withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                HapticFeedback.lightImpact();
                                                // TODO: Implement Facebook Sign In
                                                // await signInWithFacebook();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Icon(Icons.info_outline,
                                                            color:
                                                                Colors.white),
                                                        SizedBox(width: 8),
                                                        Text(
                                                            'Facebook Sign-In - Coming Soon!'),
                                                      ],
                                                    ),
                                                    backgroundColor:
                                                        Color(0xFF1877F2),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.facebook,
                                                      color: Color(0xFF1877F2),
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'Facebook',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 32),

                              // Create Account Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, "/register");
                                    },
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
