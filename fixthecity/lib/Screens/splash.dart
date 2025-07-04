import 'dart:async';
import 'dart:math' as math;

import 'package:fixthecity/Screens/home.dart';
import 'package:fixthecity/userpages/controllerpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:observe_internet_connectivity/observe_internet_connectivity.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySplash extends StatefulWidget {
  const MySplash({super.key});

  @override
  _MySplashState createState() => _MySplashState();
}

class _MySplashState extends State<MySplash> with TickerProviderStateMixin {
  bool _isConnected = false;
  StreamSubscription<bool>? _subscription;

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _backgroundAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _checkConnection();
    _listenToConnectionChanges();
    _fetchInitialData();
  }

  void _initializeAnimations() {
    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    // Start background animation immediately
    _backgroundController.forward();

    // Start logo animation after a delay
    Timer(const Duration(milliseconds: 500), () {
      _logoController.forward();
    });

    // Start text animation after logo
    Timer(const Duration(milliseconds: 1200), () {
      _textController.forward();
    });

    // Start particle animation
    Timer(const Duration(milliseconds: 800), () {
      _particleController.repeat();
    });

    // Start pulse animation and repeat
    Timer(const Duration(milliseconds: 2000), () {
      _pulseController.repeat(reverse: true);
    });
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final isSignedIn = prefs.containsKey('userId');

    if (isSignedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyCont()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHome()),
      );
    }
  }

  Future<void> _checkConnection() async {
    final hasInternet = await InternetConnectivity().hasInternetConnection;
    setState(() {
      _isConnected = hasInternet;
    });
    if (_isConnected) {
      print("Internet connection is available");
    } else {
      print("No internet connection");
      _showToast('No Internet Connection');
    }
  }

  void _listenToConnectionChanges() {
    _subscription = InternetConnectivity()
        .observeInternetConnection
        .listen((bool hasInternetAccess) {
      if (!hasInternetAccess) {
        _showToast('No Internet Connection');
      }
    });
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _fetchInitialData() async {
    await Future.delayed(Duration(seconds: 6));
    await checkAuthState();
    await Future.delayed(const Duration(seconds: 7));
    _subscription?.cancel();
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Internet Connection'),
          content: Text('Please check your internet connection and try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnection();
                _fetchInitialData();
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _logoController,
          _textController,
          _particleController,
          _pulseController,
        ]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1A0A2E),
                    const Color(0xFF16213E),
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF0F3460),
                    const Color(0xFF533483),
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF533483),
                    const Color(0xFF7209B7),
                    _backgroundAnimation.value,
                  )!,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(15, (index) => _buildParticle(index)),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      SlideTransition(
                        position: _logoSlideAnimation,
                        child: FadeTransition(
                          opacity: _logoOpacityAnimation,
                          child: ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        colors: [
                                          Color(0xFF9C27B0),
                                          Color(0xFF673AB7),
                                          Color(0xFF3F51B5),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF9C27B0).withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.smart_toy_rounded,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // App title
                      SlideTransition(
                        position: _textSlideAnimation,
                        child: FadeTransition(
                          opacity: _textOpacityAnimation,
                          child: Column(
                            children: [
                              const Text(
                                'AI-Powered',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white70,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFE1BEE7),
                                    Color(0xFFBA68C8),
                                    Color(0xFF9C27B0),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Smart Community',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Complaint App',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white60,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Loading indicator
                      FadeTransition(
                        opacity: _textOpacityAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height:14),

                            const SpinKitWave(
                              color: Color(0xFFBA68C8),
                              size: 48.0,
                              type: SpinKitWaveType.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Initializing...',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final size = random.nextDouble() * 4 + 2;
    final initialX = random.nextDouble();
    final initialY = random.nextDouble();
    final speed = random.nextDouble() * 0.5 + 0.1;

    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        final progress = (_particleAnimation.value + speed) % 1.0;
        final x = (initialX + progress * 0.1) % 1.0;
        final y = (initialY + progress * 0.2) % 1.0;

        return Positioned(
          left: x * MediaQuery.of(context).size.width,
          top: y * MediaQuery.of(context).size.height,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1 + random.nextDouble() * 0.3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withOpacity(0.2),
                  blurRadius: size,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}