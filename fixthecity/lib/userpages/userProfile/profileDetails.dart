import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'dart:math' as math;

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage>
    with TickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  bool isLoading = true;
  String _gender = 'Male';
  bool isSaving = false;

  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Controllers for the text fields
  final addressController = TextEditingController();
  final postalCodeController = TextEditingController();
  final homeNumberController = TextEditingController();
  final stateController = TextEditingController();
  final jobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    loadPageContent();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<double>(
      begin: 30.0,
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
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    homeNumberController.dispose();
    stateController.dispose();
    jobController.dispose();
    super.dispose();
  }

  Future<void> loadPageContent() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isLoading = false;
    });
    _animationController.forward();
  }

  void showTopAlert(BuildContext context, String message, {bool isSuccess = true}) {
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSuccess
                    ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                    : [const Color(0xFFE53E3E), const Color(0xFFFC8181)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> saveToFirebase() async {
    setState(() {
      isSaving = true;
    });

    if (formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'state': stateController.text,
          'homeAddress': addressController.text,
          'postal_code': postalCodeController.text,
          'home_number': homeNumberController.text,
          'job_title': jobController.text,
          'gender': _gender,
          'isProfileCompleted': true,
        });

        setState(() {
          isSaving = false;
        });

        if (formKey.currentState != null) {
          formKey.currentState!.reset();
        }

        _clearControllers();
        Navigator.pop(context, true);
        showTopAlert(context, 'Profile details saved successfully!');
      } else {
        setState(() {
          isSaving = false;
        });
        showTopAlert(context, 'User not logged in.', isSuccess: false);
      }
    } else {
      setState(() {
        isSaving = false;
      });
    }
  }

  void _clearControllers() {
    stateController.clear();
    addressController.clear();
    postalCodeController.clear();
    homeNumberController.clear();
    jobController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          _buildContent(),
          if (isSaving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF6A5ACD)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF6A5ACD),
            Color(0xFF9370DB),
            Color(0xFFBA55D3),
          ],
        ).createShader(bounds),
        child: const Text(
          'Complete Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F6FF),
            Color(0xFFE8DEFF),
            Color(0xFFD6C9FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Floating geometric shapes
          ...List.generate(5, (index) => _buildFloatingShape(index)),
        ],
      ),
    );
  }

  Widget _buildFloatingShape(int index) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final offset = math.sin(_floatingController.value * 2 * math.pi + index) * 20;
        return Positioned(
          top: 100 + (index * 80) + offset,
          left: index.isEven ? -50 : MediaQuery.of(context).size.width - 50,
          child: Transform.rotate(
            angle: _floatingController.value * 2 * math.pi + index,
            child: Container(
              width: 60 + (index * 10),
              height: 60 + (index * 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9370DB).withOpacity(0.1),
                    const Color(0xFF8A2BE2).withOpacity(0.05),
                  ],
                ),
                shape: index.isEven ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: index.isOdd ? BorderRadius.circular(15) : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: isLoading ? _buildShimmerLoading() : _buildForm(),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        // Welcome Card Shimmer
        Shimmer.fromColors(
          baseColor: const Color(0xFFE1D7FF),
          highlightColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Form Fields Shimmer (5 fields)
        ...List.generate(5, (index) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFE1D7FF),
                highlightColor: Colors.white,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 12,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
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

        const SizedBox(height: 10),

        // Gender Selection Shimmer
        Shimmer.fromColors(
          baseColor: const Color(0xFFE1D7FF),
          highlightColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(3, (index) =>
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Save Button Shimmer
        Shimmer.fromColors(
          baseColor: const Color(0xFFE1D7FF),
          highlightColor: Colors.white,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildForm() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 30),
                  _buildFormField(
                    controller: stateController,
                    label: 'State/Province',
                    hint: 'Bagmati',
                    icon: Icons.location_city_rounded,
                    index: 0,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: addressController,
                    label: 'Home Address',
                    hint: 'Municipality-Ward, District',
                    icon: Icons.location_on_rounded,
                    index: 1,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: postalCodeController,
                    label: 'Zip/Postal Code',
                    hint: '90712',
                    icon: Icons.local_post_office_rounded,
                    keyboardType: TextInputType.number,
                    index: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your postal code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: homeNumberController,
                    label: 'Home Number',
                    hint: 'Optional',
                    icon: Icons.home_rounded,
                    keyboardType: TextInputType.number,
                    index: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: jobController,
                    label: 'Job Title or Position',
                    hint: 'e.g. Civil Engineer',
                    icon: Icons.work_rounded,
                    index: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your position';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildGenderSelection(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A2BE2),
            Color(0xFF9370DB),
            Color(0xFFBA55D3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Almost There!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your profile to unlock all features',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int index,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 200)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9370DB).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF9370DB).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D1B69),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hint,
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      labelStyle: TextStyle(
                        color: const Color(0xFF6A5ACD).withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      hintStyle: TextStyle(
                        color: const Color(0xFF9370DB).withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      errorStyle: const TextStyle(
                        color: Color(0xFFE53E3E),
                        fontWeight: FontWeight.w500,
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

  Widget _buildGenderSelection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF9370DB).withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9370DB).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B69),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: ['Male', 'Female', 'Other'].map((gender) {
                    final isSelected = _gender == gender;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = gender),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                              colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                            )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFF9370DB).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                    color: const Color(0xFF9370DB).withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Color(0xFF8A2BE2),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                gender,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF6A5ACD),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF8A2BE2),
                  Color(0xFF9370DB),
                  Color(0xFFBA55D3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A2BE2).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: saveToFirebase,
                child: Container(
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Save Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A2BE2).withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Saving Profile...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D1B69),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}