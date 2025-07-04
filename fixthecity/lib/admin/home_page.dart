import 'package:flutter/material.dart';
import 'package:fixthecity/admin/home_admin.dart';
import 'package:fixthecity/admin/review/review_feedback.dart';
import 'package:fixthecity/admin/list_users.dart';
import 'dart:math' as math;
import 'dart:ui';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _cardController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _controller.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF4A148C),
              Color(0xFF1A0A2E),
              Color(0xFF0F051D),
            ],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildStatsSection(),
                      _buildDashboardCards(),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.purple.withOpacity(0.5),
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Smart Community Management',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.purple[200],
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      height: 120,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              children: [
                _buildStatCard('Total\nComplaints', '247', Icons.report_problem, Color(0xFF9C27B0)),
                SizedBox(width: 12),
                _buildStatCard('Active\nUsers', '1.2K', Icons.people, Color(0xFF7B1FA2)),
                SizedBox(width: 12),
                _buildStatCard('Resolved\nToday', '12', Icons.check_circle, Color(0xFF673AB7)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildDashboardCard(
            'Manage Complaints',
            'Review and resolve community issues',
            Icons.report_problem_outlined,
            LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF673AB7)]),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => HomeAdmin())),
            0,
          ),
          SizedBox(height: 16),
          _buildDashboardCard(
            'Manage Users',
            'View and manage user accounts',
            Icons.people_outline,
            LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF512DA8)]),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => UsersPage())),
            200,
          ),
          SizedBox(height: 16),
          _buildDashboardCard(
            'View Feedbacks',
            'Monitor user reviews and suggestions',
            Icons.reviews_outlined,
            LinearGradient(colors: [Color(0xFF673AB7), Color(0xFF3F51B5)]),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsPage())),
            400,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String subtitle, IconData icon, LinearGradient gradient, VoidCallback onTap, int delay) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      ],
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
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles = [];

  ParticlePainter(this.animationValue) {
    if (particles.isEmpty) {
      for (int i = 0; i < 50; i++) {
        particles.add(Particle());
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final offset = Offset(
        particle.x * size.width + math.sin(animationValue * 2 * math.pi + particle.phase) * 20,
        particle.y * size.height + math.cos(animationValue * 2 * math.pi + particle.phase) * 15,
      );

      canvas.drawCircle(offset, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double phase;

  Particle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 3 + 1,
        phase = math.Random().nextDouble() * 2 * math.pi;
}
