import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

enum VerificationStatus {
  pending,
  verified,
  unverified,
}

class Cprofile extends StatefulWidget {
  const Cprofile({super.key});

  @override
  State<Cprofile> createState() => _CprofileState();
}

class _CprofileState extends State<Cprofile> with TickerProviderStateMixin {
  bool isProfileDetailsCompleted = false;
  bool isGovIdUploaded = false;
  VerificationStatus verificationStatus = VerificationStatus.pending;
  bool isLoading = true;
  String? adminMessage; // For storing admin feedback messages

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Purple theme colors
  static const Color primaryPurple = Color(0xFF6A4C93);
  static const Color lightPurple = Color(0xFF9B7EBD);
  static const Color deepPurple = Color(0xFF4A306D);
  static const Color accentPurple = Color(0xFF8E44AD);
  static const Color purpleGradientStart = Color(0xFF667eea);
  static const Color purpleGradientEnd = Color(0xFF764ba2);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    loadAndSyncCompletionStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadAndSyncCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'verificationStatus': 'pending',
          'isProfileCompleted': false,
          'isGovIdUploaded': false,
          'adminMessage': null,
        });
      }
      final data = doc.data()!;
      final status = data['verificationStatus'] ?? 'pending';
      final profileStatus = data['isProfileCompleted'] ?? false;
      final govIdStatus = data['isGovIdUploaded'] ?? false;
      final message = data['adminMessage'];

      setState(() {
        isProfileDetailsCompleted = profileStatus;
        isGovIdUploaded = govIdStatus;
        adminMessage = message;
        verificationStatus = VerificationStatus.values.firstWhere(
              (e) => e.toString() == 'VerificationStatus.$status',
          orElse: () => VerificationStatus.pending,
        );
        isLoading = false;
      });

      await prefs.setBool('isProfileDetailsCompleted', isProfileDetailsCompleted);
      await prefs.setBool('isGovIdUploaded', isGovIdUploaded);
      await prefs.setString('verificationStatus', verificationStatus.toString().split('.').last);
      if (message != null) {
        await prefs.setString('adminMessage', message);
      }
    } else {
      setState(() {
        isProfileDetailsCompleted = prefs.getBool('isProfileDetailsCompleted') ?? false;
        isGovIdUploaded = prefs.getBool('isGovIdUploaded') ?? false;
        adminMessage = prefs.getString('adminMessage');
        final status = prefs.getString('verificationStatus') ?? 'pending';
        verificationStatus = VerificationStatus.values.firstWhere(
              (e) => e.toString() == 'VerificationStatus.$status',
          orElse: () => VerificationStatus.pending,
        );
        isLoading = false;
      });
    }

    _animationController.forward();
  }

  Future<void> saveCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    // Update local storage
    await prefs.setBool('isProfileDetailsCompleted', isProfileDetailsCompleted);
    await prefs.setBool('isGovIdUploaded', isGovIdUploaded);
    await prefs.setString('verificationStatus', verificationStatus.toString().split('.').last);

    // Update Firebase
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.update({
        'isProfileCompleted': isProfileDetailsCompleted,
        'isGovIdUploaded': isGovIdUploaded,
        'verificationStatus': verificationStatus.toString().split('.').last,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showAccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: deepPurple,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(
                  color: primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _canAccessProfileDetails() {
    return !isProfileDetailsCompleted || verificationStatus == VerificationStatus.unverified;
  }

  bool _canAccessGovIdUpload() {
    return isProfileDetailsCompleted &&
        (!isGovIdUploaded || verificationStatus == VerificationStatus.unverified);
  }

  Future<void> navigateToProfileDetails() async {
    if (!_canAccessProfileDetails()) {
      _showAccessDialog(
        title: 'Step Already Completed',
        message: 'Your profile details have already been submitted and are ${verificationStatus == VerificationStatus.verified ? 'verified' : 'under review'}. You can only modify them if verification fails.',
        icon: Icons.check_circle_outline,
        color: verificationStatus == VerificationStatus.verified ? Colors.green : Colors.orange,
      );
      return;
    }

    final result = await Navigator.pushNamed(context, '/profile-details');
    if (result == true) {
      setState(() {
        isProfileDetailsCompleted = true;
      });
      await saveCompletionStatus();
    }
  }

  Future<void> navigateToUploadGovId() async {
    if (!isProfileDetailsCompleted) {
      _showAccessDialog(
        title: 'Complete Profile First',
        message: 'Please complete your profile details before uploading government ID documents.',
        icon: Icons.info_outline,
        color: Colors.orange,
      );
      return;
    }

    if (!_canAccessGovIdUpload()) {
      _showAccessDialog(
        title: 'Document Already Submitted',
        message: 'Your government ID has already been submitted and is ${verificationStatus == VerificationStatus.verified ? 'verified' : 'under review'}. You can only resubmit if verification fails.',
        icon: Icons.check_circle_outline,
        color: verificationStatus == VerificationStatus.verified ? Colors.green : Colors.orange,
      );
      return;
    }

    final result = await Navigator.pushNamed(context, '/upload-gov-id');
    if (result == true) {
      setState(() {
        isGovIdUploaded = true;
      });
      await saveCompletionStatus();
    }
  }

  Future<void> _refreshProfile() async {
    await loadAndSyncCompletionStatus();
  }

  Widget _buildStatusCard() {
    IconData statusIcon;
    String statusTitle;
    String statusMessage;
    List<Color> gradientColors;

    switch (verificationStatus) {
      case VerificationStatus.verified:
        statusIcon = Icons.verified_rounded;
        statusTitle = "Profile Verified";
        statusMessage = "You can now access all services seamlessly.";
        gradientColors = [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
        break;
      case VerificationStatus.unverified:
        statusIcon = Icons.error_rounded;
        statusTitle = "Verification Failed";
        statusMessage = adminMessage ?? "Please review and resubmit your information.";
        gradientColors = [const Color(0xFFE57373), const Color(0xFFEF5350)];
        break;
      default:
        if (isGovIdUploaded && isProfileDetailsCompleted) {
          statusIcon = Icons.hourglass_empty_rounded;
          statusTitle = "Under Review";
          statusMessage = "Your profile is being reviewed. This may take 24-48 hours.";
          gradientColors = [const Color(0xFFFFB74D), const Color(0xFFFF9800)];
        } else {
          statusIcon = Icons.assignment_rounded;
          statusTitle = "Complete Your Profile";
          statusMessage = "Update your details and verify your identity to get started.";
          gradientColors = [purpleGradientStart, purpleGradientEnd];
        }
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusMessage,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              height: 1.2,
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
        );
      },
    );
  }

  Widget _buildProgressSection() {
    int completedSteps = (isProfileDetailsCompleted ? 1 : 0) + (isGovIdUploaded ? 1 : 0);
    double progress = completedSteps / 2;

    // Dynamic colors based on progress and status
    List<Color> progressColors;
    List<Color> badgeColors;
    Color shadowColor;

    if (verificationStatus == VerificationStatus.verified) {
      progressColors = [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
      badgeColors = [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
      shadowColor = const Color(0xFF4CAF50);
    } else if (verificationStatus == VerificationStatus.unverified) {
      progressColors = [const Color(0xFFE57373), const Color(0xFFEF5350)];
      badgeColors = [const Color(0xFFE57373), const Color(0xFFEF5350)];
      shadowColor = const Color(0xFFE57373);
    } else if (completedSteps == 2) {
      // Both completed, under review
      progressColors = [const Color(0xFFFFB74D), const Color(0xFFFF9800)];
      badgeColors = [const Color(0xFFFFB74D), const Color(0xFFFF9800)];
      shadowColor = const Color(0xFFFFB74D);
    } else if (completedSteps == 1) {
      // Halfway done
      progressColors = [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
      badgeColors = [primaryPurple, accentPurple];
      shadowColor = const Color(0xFF42A5F5);
    } else {
      // Not started
      progressColors = [Colors.grey.shade400, Colors.grey.shade500];
      badgeColors = [primaryPurple, accentPurple];
      shadowColor = Colors.grey.shade400;
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Profile Progress",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: deepPurple,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: badgeColors,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: badgeColors[0].withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          verificationStatus == VerificationStatus.verified
                              ? "✓ Verified"
                              : verificationStatus == VerificationStatus.unverified
                              ? "⚠ Action Required"
                              : completedSteps == 2
                              ? "⏳ Under Review"
                              : "$completedSteps/2 Steps",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOutCubic,
                              width: constraints.maxWidth * progress,
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: progressColors,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: shadowColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            if (progress > 0 && progress < 1)
                              Positioned(
                                left: (constraints.maxWidth * progress) - 6,
                                top: -1,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 1000),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: progressColors[1],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: shadowColor.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProgressStep("Profile Details", isProfileDetailsCompleted),
                      _buildProgressStep("Gov ID Upload", isGovIdUploaded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressStep(String title, bool completed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: completed ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed ? const Color(0xFF4CAF50) : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: completed
              ? const Icon(
            Icons.check,
            size: 8,
            color: Colors.white,
          )
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: completed ? deepPurple : Colors.grey.shade600,
            fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _getButtonText(int index, bool isCompleted) {
    if (verificationStatus == VerificationStatus.verified && isCompleted) {
      return "Verified";
    }
    if (verificationStatus == VerificationStatus.unverified) {
      return "Resubmit";
    }
    if (index == 1 && isGovIdUploaded && verificationStatus == VerificationStatus.pending) {
      return "Processing";
    }
    return pc[index].buttonText;
  }

  bool _isCardAccessible(int index) {
    if (index == 0) {
      return _canAccessProfileDetails();
    } else {
      return _canAccessGovIdUpload();
    }
  }

  Widget _buildProfileCard(ProfileCompletionCard card, int index) {
    bool isCompleted = index == 0 ? isProfileDetailsCompleted : isGovIdUploaded;
    bool isVerified = isCompleted && verificationStatus == VerificationStatus.verified;
    bool needsReset = verificationStatus == VerificationStatus.unverified;
    bool isProcessing = index == 1 && isGovIdUploaded && verificationStatus == VerificationStatus.pending;
    bool isAccessible = _isCardAccessible(index);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isVerified
                ? Colors.green.withOpacity(0.12)
                : needsReset
                ? Colors.red.withOpacity(0.12)
                : primaryPurple.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (index == 0) {
              navigateToProfileDetails();
            } else {
              navigateToUploadGovId();
            }
          },
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isVerified
                    ? Colors.green.withOpacity(0.25)
                    : needsReset
                    ? Colors.red.withOpacity(0.25)
                    : isAccessible
                    ? primaryPurple.withOpacity(0.25)
                    : Colors.grey.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isVerified
                          ? [Colors.green, Colors.green.shade400]
                          : needsReset
                          ? [Colors.red, Colors.red.shade400]
                          : isAccessible
                          ? [primaryPurple, accentPurple]
                          : [Colors.grey.shade400, Colors.grey.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isVerified
                            ? Colors.green.withOpacity(0.2)
                            : needsReset
                            ? Colors.red.withOpacity(0.2)
                            : primaryPurple.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isVerified
                        ? Icons.verified_rounded
                        : needsReset
                        ? Icons.refresh_rounded
                        : isCompleted && !isAccessible
                        ? Icons.lock_outline
                        : card.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    card.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: deepPurple,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: isVerified ? null : () {
                      if (index == 0) {
                        navigateToProfileDetails();
                      } else {
                        navigateToUploadGovId();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVerified
                          ? Colors.grey.shade300
                          : needsReset
                          ? Colors.red
                          : isAccessible
                          ? primaryPurple
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      elevation: isVerified ? 0 : 2,
                      shadowColor: isVerified
                          ? Colors.transparent
                          : needsReset
                          ? Colors.red.withOpacity(0.2)
                          : primaryPurple.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _getButtonText(index, isCompleted),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isVerified ? Colors.grey.shade600 : Colors.white,
                      ),
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshProfile,
      color: primaryPurple,
      child: SingleChildScrollView(
        physics: const  NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20), // Increased bottom padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                _buildShimmerLoading()
              else ...[
                _buildStatusCard(),
                const SizedBox(height: 24), // Much smaller spacing
                _buildProgressSection(),
                const SizedBox(height: 24), // Much smaller spacing
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.3),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Complete Steps",
                                    style: TextStyle(
                                      fontSize: 16, // Smaller text
                                      fontWeight: FontWeight.bold,
                                      color: deepPurple,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Swipe to see all",
                                        style: TextStyle(
                                          fontSize: 10, // Smaller text
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.swipe_left,
                                        size: 14, // Smaller icon
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16), // Smaller spacing
                            SizedBox(
                              height: 170,
                              // Much smaller height to fit everything
                              child: Stack(

                                children: [
                                  ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal:4),
                                    shrinkWrap: true,
                                    itemCount: pc.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: SizedBox(
                                          width:MediaQuery.of(context).size.width * 0.43, // 👈 set desired card width here
                                          child: _buildProfileCard(pc[index], index),
                                        ),
                                      );
                                    },
                                  ),
                                  // Gradient overlay on the right to indicate more content
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 15, // Leave space for dots
                                    child: Container(
                                      width: 25,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            const Color(0xFFF8F9FA).withOpacity(0.0),
                                            const Color(0xFFF8F9FA).withOpacity(0.8),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileCompletionCard {
  final String title;
  final String buttonText;
  final IconData icon;

  ProfileCompletionCard({
    required this.title,
    required this.buttonText,
    required this.icon,
  });
}

List<ProfileCompletionCard> pc = [
  ProfileCompletionCard(
    title: "Set Your Profile Details",
    icon: CupertinoIcons.person_circle,
    buttonText: "Continue",
  ),
  ProfileCompletionCard(
    title: "Upload your Gov-Id Documents",
    icon: CupertinoIcons.doc,
    buttonText: "Upload",
  ),
];