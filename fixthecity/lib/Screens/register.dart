import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> with TickerProviderStateMixin {
  bool _obscureText = true;
  bool _obscureConfirmText = true;

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
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
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
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    Future.delayed(const Duration(milliseconds: 150), () {
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
    nameController.dispose();
    contactController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmText = !_obscureConfirmText;
    });
  }

  final formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    } else if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
      return 'Please enter a valid name (letters and spaces only)';
    }
    return null;
  }

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

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    } else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    } else if (!RegExp(r'^(98|97)\d{8}$').hasMatch(value)) {
      return 'Please enter a valid Nepali mobile number';
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> signUp(String email, String password) async {
    if (formKey.currentState!.validate()) {
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Creating your account...',
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

      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;

        if (user != null) {
          await addUserDetails(
            user.uid,
            nameController.text.trim(),
            emailController.text.trim(),
            contactController.text.trim(),
          );

          Navigator.of(context).pop();

          Fluttertoast.showToast(
            msg: "Account created successfully!",
            backgroundColor: Colors.deepPurple,
            textColor: Colors.white,
          );
          Navigator.pushNamed(context, "/login");
        }
      } catch (e) {
        Navigator.of(context).pop();

        String errorMessage = e.toString();
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'An account with this email already exists';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'The password provided is too weak';
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
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> addUserDetails(String uid, String name, String email, String contact) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'contact': contact,
      'verificationStatus': 'pending',
      'isProfileCompleted': false,
      'isGovIdUploaded': false,
    });
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool hasToggle = false,
    VoidCallback? onToggle,
    bool toggleValue = false,
    int animationDelay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + animationDelay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                validator: validator,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade300,
                          Colors.purple.shade600,
                        ],
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  suffixIcon: hasToggle
                      ? IconButton(
                    icon: Icon(
                      toggleValue
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.deepPurple,
                    ),
                    onPressed: onToggle,
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
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
    );
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
                                            color: Colors.deepPurple.withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),child: Icon(
                                      FontAwesomeIcons.userAstronaut,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // App Title with Animation
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.deepPurple,
                                  Colors.purple.shade600,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Join Our Community',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const Text(
                              'Create your account to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 32),

                            // Input Fields with Staggered Animation
                            _buildInputField(
                              controller: nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: validateFullName,
                              animationDelay: 0,
                            ),

                            _buildInputField(
                              controller: emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              validator: validateEmail,
                              animationDelay: 100,
                            ),

                            _buildInputField(
                              controller: contactController,
                              label: 'Contact Number',
                              icon: Icons.phone_outlined,
                              validator: validateMobileNumber,
                              animationDelay: 200,
                            ),

                            _buildInputField(
                              controller: passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              validator: validatePassword,
                              obscureText: _obscureText,
                              hasToggle: true,
                              onToggle: _togglePasswordVisibility,
                              toggleValue: _obscureText,
                              animationDelay: 300,
                            ),

                            _buildInputField(
                              controller: confirmPasswordController,
                              label: 'Confirm Password',
                              icon: Icons.lock_outline,
                              validator: (value) => validateConfirmPassword(value, passwordController.text),
                              obscureText: _obscureConfirmText,
                              hasToggle: true,
                              onToggle: _toggleConfirmPasswordVisibility,
                              toggleValue: _obscureConfirmText,
                              animationDelay: 400,
                            ),

                            const SizedBox(height: 8),

                            // Animated Register Button
                            TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 1200),
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
                                          color: Colors.deepPurple.withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        signUp(emailController.text, passwordController.text);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                      child: const Text(
                                        'CREATE ACCOUNT',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
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

                            // Social Registration Buttons
                            TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 1400),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Column(
                                      children: [
                                        // Google Sign Up
                                        Container(
                                          width: double.infinity,
                                          height: 55,
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.1),
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

                                        // Facebook Sign Up
                                        Container(
                                          width: double.infinity,
                                          height: 55,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF1877F2),
                                                Color(0xFF42A5F5),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0xFF1877F2).withOpacity(0.4),
                                                blurRadius: 15,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              HapticFeedback.lightImpact();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(Icons.info_outline, color: Colors.white),
                                                      SizedBox(width: 8),
                                                      Text('Facebook Sign-Up - Coming Soon!'),
                                                    ],
                                                  ),
                                                  backgroundColor: Color(0xFF1877F2),
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
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
                                                  'fracebook',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
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

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, "/login");
                                  },
                                  child: const Text(
                                    'Sign In',
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
    );
  }
}