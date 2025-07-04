import 'package:fixthecity/userpages/Home/widgets/modeltest.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../components/UserFunctions/helpSupport.dart';

class CustomDrawer extends StatefulWidget {
  final Function(int) onPageChanged;
  final VoidCallback onShowEmergencyContacts;
  final VoidCallback onShowAbout;
  final VoidCallback onSignOut;

  const CustomDrawer({
    Key? key,
    required this.onPageChanged,
    required this.onShowEmergencyContacts,
    required this.onShowAbout,
    required this.onSignOut,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shakeController;
  late AnimationController _logoController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _logoRotation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _shakeAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticInOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.linear,
    ));

    _animationController.forward();
    _shakeController.repeat(reverse: true);
    _logoController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shakeController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          width: 280,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade800,
                    Colors.purple.shade700,
                    Colors.deepPurple.shade900,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      _buildLogoHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              // Main Navigation Section
                              _buildAnimatedMenuItem(
                                icon: Icons.home_rounded,
                                title: "Home",
                                delay: 0,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onPageChanged(0);
                                },
                              ),
                              // Action Section
                              _buildAnimatedMenuItem(
                                icon: Icons.add_circle_rounded,
                                title: "Report Issue",
                                delay: 400,
                                isHighlighted: true,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onPageChanged(1);

                                  // Add navigation to report issue
                                },
                              ),
                              // _buildAnimatedMenuItem(
                              //   icon: Icons.report_problem_rounded,
                              //   title: "My Complaints",
                              //   delay: 50,
                              //   onTap: () {
                              //     Navigator.pop(context);
                              //     // Add navigation to complaints page
                              //   },
                              // ),
                              // _buildAnimatedMenuItem(
                              //   icon: Icons.notifications_rounded,
                              //   title: "Notifications",
                              //   delay: 100,
                              //   onTap: () {
                              //     Navigator.pop(context);
                              //     // Add navigation to notifications
                              //   },
                              // ),

                              // Spacer & Divider
                              const SizedBox(height: 15),
                              // _buildDivider(),
                              // const SizedBox(height: 15),

                              // // User Section
                              // _buildAnimatedMenuItem(
                              //   icon: Icons.person_rounded,
                              //   title: "Profile",
                              //   delay: 150,
                              //   onTap: () {
                              //     Navigator.pop(context);
                              //     // Add navigation to profile
                              //   },
                              // ),
                              // _buildAnimatedMenuItem(
                              //   icon: Icons.settings_rounded,
                              //   title: "Settings",
                              //   delay: 200,
                              //   onTap: () {
                              //     Navigator.pop(context);
                              //     // Add navigation to settings
                              //   },
                              // ),

                              // Spacer & Divider
                              const SizedBox(height: 15),
                              _buildDivider(),
                              const SizedBox(height: 15),
                              // Community Section
                              _buildAnimatedMenuItem(
                                icon: Icons.newspaper_outlined,
                                title: "News",
                                delay: 250,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => NewsPage()),
                                  );
                                },
                              ),

                              // Community Section
                              _buildAnimatedMenuItem(
                                icon: Icons.emergency_rounded,
                                title: "Emergency Contacts",
                                delay: 250,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onShowEmergencyContacts();
                                },
                              ),
                              // _buildAnimatedMenuItem(
                              //   icon: Icons.group_rounded,
                              //   title: "Community Guidelines",
                              //   delay: 300,
                              //   onTap: () {
                              //     Navigator.pop(context);
                              //     // Add navigation to guidelines
                              //   },
                              // ),
                              // _buildAnimatedMenuItem(
                              //   icon: Icons.help_center_rounded,
                              //   title: "Help & Support",
                              //   delay: 350,
                              //   onTap: () {
                              //     Navigator.pop(context);
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(builder: (context) => HelpAndSupportPage()),
                              //     );
                              //   },
                              // ),

                              // Spacer & Divider
                              const SizedBox(height: 15),
                              _buildDivider(),
                              const SizedBox(height: 15),


                              // _buildAnimatedMenuItem(
                              //   icon: Icons.feedback_rounded,
                              //   title: "Feedback",
                              //   delay: 450,
                              //   onTap: () {
                              //     Navigator.pop(context);
                              //     // Add navigation to feedback
                              //   },
                              // ),
                              _buildAnimatedMenuItem(
                                icon: Icons.info_rounded,
                                title: "About",
                                delay: 500,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onShowAbout();
                                },
                              ),

                              const SizedBox(height: 20),
                              _buildLogoutItem(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoHeader() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Container(
            height: 180,
            margin: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo container with rotation and shake
                AnimatedBuilder(
                  animation: Listenable.merge([_logoRotation, _shakeAnimation]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value * 0.5, 0),
                      child: Transform.rotate(
                        angle: _logoRotation.value * 0.1, // Subtle rotation
                        child: Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                "assets/Akar_logo.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.8),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    "Smart Community",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "AI Enhanced Platform",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMenuItem({
    required IconData icon,
    required String title,
    required int delay,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 300, 0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300 + delay),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: _ShakingMenuItem(
              icon: icon,
              title: title,
              onTap: onTap,
              shakeAnimation: _shakeAnimation,
              isHighlighted: isHighlighted,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 300, 0),
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value * 0.3, 0),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withOpacity(0.2),
                        Colors.pink.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: widget.onSignOut,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.withOpacity(0.6),
                                        Colors.pink.withOpacity(0.4),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "Logout",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ShakingMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Animation<double> shakeAnimation;
  final bool isHighlighted;

  const _ShakingMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.shakeAnimation,
    this.isHighlighted = false,
  });

  @override
  State<_ShakingMenuItem> createState() => _ShakingMenuItemState();
}

class _ShakingMenuItemState extends State<_ShakingMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, widget.shakeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.shakeAnimation.value * 0.5, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isHighlighted
                      ? [
                    Colors.orange.withOpacity(0.3),
                    Colors.deepOrange.withOpacity(0.2),
                  ]
                      : [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
                  ],
                ),
                border: Border.all(
                  color: widget.isHighlighted
                      ? Colors.orange.withOpacity(0.4)
                      : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: _isHovered
                    ? [
                  BoxShadow(
                    color: widget.isHighlighted
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.deepPurple.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: const Offset(0, -5),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: widget.isHighlighted
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.onTap,
                      onHover: (hovered) {
                        setState(() {
                          _isHovered = hovered;
                        });
                        if (hovered) {
                          _hoverController.forward();
                        } else {
                          _hoverController.reverse();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: widget.isHighlighted
                                      ? [
                                    Colors.orange.withOpacity(0.8),
                                    Colors.deepOrange.withOpacity(0.6),
                                  ]
                                      : [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.6),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.isHighlighted
                                        ? Colors.orange.withOpacity(0.3)
                                        : Colors.deepPurple.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.isHighlighted
                                    ? Colors.white
                                    : Colors.deepPurple.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  color: widget.isHighlighted
                                      ? Colors.orange.shade100
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: widget.isHighlighted
                                  ? Colors.orange.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                              size: 16,
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
        );
      },
    );
  }
}