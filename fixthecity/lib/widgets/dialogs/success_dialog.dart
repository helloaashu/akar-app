import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessDialog extends StatefulWidget {
  final String complaintId;

  const SuccessDialog({Key? key, required this.complaintId}) : super(key: key);

  static void show(BuildContext context, String complaintId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => SuccessDialog(complaintId: complaintId),
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create animations
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start scale animation first
    _scaleController.forward();

    // Delay and start slide animation
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();

    // Start fade animation
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    // Show confetti after success animation
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _showConfetti = true;
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [

          // Main dialog content
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                    margin: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color(0xFFF8FFF8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 5,
                        ),
                        const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 30,
                          offset: Offset(0, 20),
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.green.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                        children: [
                        // Background confetti - contained within dialog
                        if (_showConfetti)
                    Positioned.fill(
                child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Lottie.asset(
                  'assets/animation/confetti.json',
                  repeat: false,
                  fit: BoxFit.contain,
                ),
              ),
              ),

              // Main content
              SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Success Icon with Animation
              SlideTransition(
              position: _slideAnimation,
              child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
              return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
              colors: [
              Colors.green.withOpacity(0.1),
              Colors.transparent,
              ],
              ),
              ),
              child: Lottie.asset(
              'assets/animation/success.json',
              height: 80,
              repeat: false,
              ),
              ),
              );
              },
              ),
              ),

              const SizedBox(height: 16),

              // Success Title
              FadeTransition(
              opacity: _fadeAnimation,
              child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
              colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
              ],
              ).createShader(bounds),
              child: const Text(
              'Success!',
              style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
              ),
              ),
              ),
              ),

              const SizedBox(height: 8),

              // Decorative line
              FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
              gradient: const LinearGradient(
              colors: [
              Color(0xFF4CAF50),
              Color(0xFF8BC34A),
              ],
              ),
              borderRadius: BorderRadius.circular(2),
              ),
              ),
              ),

              const SizedBox(height: 18),

              // Success Message
              FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
              'Your complaint has been submitted successfully!',
              style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              ),
              ),

              const SizedBox(height: 20),

              // Complaint ID Container
              FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
              gradient: LinearGradient(
              colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
              ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1,
              ),
              ),
              child: Column(
              children: [
              const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(
              Icons.confirmation_number_outlined,
              color: Color(0xFF2E7D32),
              size: 18,
              ),
              SizedBox(width: 6),
              Text(
              'Complaint ID',
              style: TextStyle(
              fontSize: 13,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
              ),
              ),
              ],
              ),
              const SizedBox(height: 6),
              Text(
              widget.complaintId,
              style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              letterSpacing: 0.5,
              ),
              ),
              ],
              ),
              ),
              ),

              const SizedBox(height: 12),

              // Reference Note
              FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(
              Icons.info_outline,
              size: 14,
              color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Flexible(
              child: Text(
              'Keep this ID for reference',
              style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              ),
              ),
              ),
              ],
              ),
              ),

              const SizedBox(height: 24),

              // Action Button
              FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
              decoration: BoxDecoration(
              gradient: const LinearGradient(
              colors: [
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
              ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
              BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              ),
              ],
              ),
              child: ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              ),
              ),
              onPressed: () {
              Future.delayed(
              const Duration(milliseconds: 100),
              () => Navigator.of(context).pop(),
              );
              },
              child: const Text(
              'Continue',
              style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              ),
              ),
              ),
              ),
              ),
              ),
              ],
              ),
              ),
              ]),
                ));
            },
          ),
        ],
      ),
    );
  }
}