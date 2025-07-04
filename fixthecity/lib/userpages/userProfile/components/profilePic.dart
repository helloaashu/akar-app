import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

enum VerificationStatus {
  pending,
  verified,
  unverified,
}

class ProfilePic extends StatefulWidget {
  const ProfilePic({Key? key}) : super(key: key);

  @override
  _ProfilePicState createState() => _ProfilePicState();
}

class _ProfilePicState extends State<ProfilePic> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("users");
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  String? _profileImageURL;
  String? _username;
  String? _email;
  VerificationStatus verificationStatus = VerificationStatus.pending;
  bool _isLoading = true;
  File? _verifiedIcon;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _cardController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Enhanced Purple theme colors
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color secondaryPurple = Color(0xFF8F7BED);
  static const Color lightPurple = Color(0xFFE8E3FF);
  static const Color darkPurple = Color(0xFF5A4FCF);
  static const Color accentPurple = Color(0xFFA29BFE);
  static const Color ultraLightPurple = Color(0xFFF5F3FF);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProfile();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // Helper method to get the appropriate image provider
  ImageProvider _getProfileImageProvider() {
    // For Google users, use their Google profile image directly
    if (_isGoogleUser() && currentUser.photoURL != null) {
      return NetworkImage(currentUser.photoURL!);
    }
    // For other users, use cached image if available
    else if (_profileImage != null) {
      return FileImage(_profileImage!);
    }
    // Use Firestore image URL if available
    else if (_profileImageURL != null) {
      return NetworkImage(_profileImageURL!);
    }
    // Fallback to default image
    else {
      return const AssetImage("assets/Profile Image.png") as ImageProvider;
    }
  }

  // Helper method to check if user signed in with Google
  bool _isGoogleUser() {
    return currentUser.providerData.any((provider) => provider.providerId == 'google.com');
  }

  Future<void> _loadUserProfile() async {
    final doc = await usersCollection.doc(currentUser.uid).get();

    setState(() {
      // Use Google profile image for Google users, otherwise use Firestore image
      if (_isGoogleUser() && currentUser.photoURL != null) {
        _profileImageURL = currentUser.photoURL;
      } else {
        _profileImageURL = doc.data()?['profileImageURL'];
      }

      // Use Google display name for Google users, otherwise use Firestore name
      if (_isGoogleUser() && currentUser.displayName != null) {
        _username = currentUser.displayName;
      } else {
        _username = doc.data()?['name'];
      }

      _email = currentUser.email;
      final status = doc.data()?['verificationStatus'] ?? 'pending';
      verificationStatus = VerificationStatus.values.firstWhere(
            (e) => e.toString() == 'VerificationStatus.$status',
        orElse: () => VerificationStatus.pending,
      );
    });

    await Future.wait([
      _loadProfileImage(),
      _loadVerifiedIcon(),
    ]);

    setState(() {
      _isLoading = false;
    });

    // Start card animation after loading
    _cardController.forward();
  }

  Future<void> _loadProfileImage() async {
    if (_profileImageURL != null) {
      try {
        // For Google users, use NetworkImage directly (no caching)
        // For other users, use cached image
        if (_isGoogleUser() && currentUser.photoURL != null) {
          // Don't cache Google profile images, they're already optimized
          return;
        } else {
          final file = await DefaultCacheManager().getSingleFile(_profileImageURL!);
          setState(() {
            _profileImage = file;
          });
        }
      } catch (e) {
        print('Error loading profile image: $e');
      }
    }
  }

  Future<void> _loadVerifiedIcon() async {
    if (verificationStatus == VerificationStatus.verified) {
      try {
        final file = await DefaultCacheManager().getSingleFile('assets/verified.png');
        setState(() {
          _verifiedIcon = file;
        });
      } catch (e) {
        print('Error loading verified icon: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');

      await storageRef.putFile(_profileImage!);
      final downloadURL = await storageRef.getDownloadURL();

      await usersCollection.doc(currentUser.uid).update({'profileImageURL': downloadURL});
      setState(() {
        _profileImageURL = downloadURL;
      });

      // Update cached image
      await DefaultCacheManager().downloadFile(downloadURL);
    }
  }

  Widget _buildShimmerCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 350),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: lightPurple.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.8),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Profile picture shimmer
              Container(
                height: 157,
                width: 112,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Name shimmer
              Container(
                width: 160,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              // Email shimmer
              Container(
                width: 200,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryPurple,
            secondaryPurple,
            accentPurple,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundImage: _getProfileImageProvider(),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryPurple,
              darkPurple,
            ],
          ),
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _pickImage,
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
    );
  }

  Widget _buildVerificationBadge() {
    if (verificationStatus != VerificationStatus.verified) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                color: Colors.green.shade600,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Verified",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
    );
  }

  Widget _buildFloatingCard() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 350),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    ultraLightPurple,
                  ],
                ),
                border: Border.all(
                  color: lightPurple.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Picture with Camera Button
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _buildProfileAvatar(),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _buildCameraButton(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Verification Badge
                    _buildVerificationBadge(),
                    if (verificationStatus == VerificationStatus.verified)
                      const SizedBox(height: 16),

                    // User Name
                    if (_username != null) ...[
                      Text(
                        _username!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: darkPurple,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // User Email
                    if (_email != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: lightPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentPurple.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _email!,
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryPurple.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Center(
        child: _isLoading ? _buildShimmerCard() : _buildFloatingCard(),
      ),
    );
  }
}