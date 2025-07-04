import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

class UploadId extends StatefulWidget {
  const UploadId({super.key});

  @override
  State<UploadId> createState() => _UploadIdState();
}

class _UploadIdState extends State<UploadId> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isMinor = false;
  File? _citizenshipImage;
  File? _schoolIdImage;
  String? _citizenshipNumber;
  String? _schoolName;
  String? _studentId;
  DateTime? _issuedDate;
  final _issuedDistrictController = TextEditingController();
  String? _issuedDistrict;

  final _issuedDateFormatter = MaskTextInputFormatter(
    mask: '####/##/##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _issuedDateController = TextEditingController();
  final _citizenshipController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late AnimationController _imageController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _imageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 40.0,
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
    _imageController.dispose();
    _issuedDistrictController.dispose();
    _issuedDateController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      String imageName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String imagePath = 'idImages/$imageName';

      await _storage.ref(imagePath).putFile(imageFile);
      return await _storage.ref(imagePath).getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      return null;
    }
  }

  Future<void> _pickImages(ImageSource source, bool isSchoolId) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isSchoolId) {
          _schoolIdImage = File(pickedFile.path);
        } else {
          _citizenshipImage = File(pickedFile.path);
        }
      });
      _imageController.forward().then((_) {
        _imageController.reverse();
      });
    }
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

  void _saveForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if ((!_isMinor && _citizenshipImage == null) ||
          (_isMinor && _schoolIdImage == null)) {
        showTopAlert(context, 'Please upload the required image.', isSuccess: false);
        return;
      }

      _formKey.currentState?.save();
      setState(() {
        _isSaving = true;
      });

      String? imageUrl;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (!_isMinor && _citizenshipImage != null) {
          imageUrl = await _uploadImage(_citizenshipImage!, user.uid);
        } else if (_isMinor && _schoolIdImage != null) {
          imageUrl = await _uploadImage(_schoolIdImage!, user.uid);
        }

        final updateData = {
          'isMinor': _isMinor,
          'citizenshipNumber': _isMinor ? null : _citizenshipNumber,
          'schoolName': _isMinor ? _schoolName : null,
          'studentId': _isMinor ? _studentId : null,
          'idImageURL': imageUrl,
          'isGovIdUploaded': true,
          'issuedDate': _issuedDate,
          'issuedDistrict': _issuedDistrict,
          'verificationStatus': 'pending',
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);

        setState(() {
          _isSaving = false;
        });

        if (_formKey.currentState != null) {
          _formKey.currentState!.reset();
        }

        Navigator.pop(context, true);
        showTopAlert(context, 'Document uploaded successfully!');
      } else {
        setState(() {
          _isSaving = false;
        });
        showTopAlert(context, 'User not logged in.', isSuccess: false);
      }
    }
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
          if (_isSaving) _buildLoadingOverlay(),
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
          'Verify Identity',
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
          ...List.generate(4, (index) => _buildFloatingShape(index)),
        ],
      ),
    );
  }

  Widget _buildFloatingShape(int index) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final offset = math.sin(_floatingController.value * 2 * math.pi + index) * 15;
        return Positioned(
          top: 120 + (index * 100) + offset,
          left: index.isEven ? -40 : MediaQuery.of(context).size.width - 60,
          child: Transform.rotate(
            angle: _floatingController.value * 2 * math.pi + index,
            child: Container(
              width: 50 + (index * 8),
              height: 50 + (index * 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9370DB).withOpacity(0.1),
                    const Color(0xFF8A2BE2).withOpacity(0.05),
                  ],
                ),
                shape: index.isEven ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: index.isOdd ? BorderRadius.circular(12) : null,
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
      child: _isLoading ? _buildShimmerLoading() : _buildForm(),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        // Security Header Shimmer
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
                        width: 150,
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

        // Form Fields Shimmer
        ...List.generate(6, (index) =>
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
                ),
              ),
            ),
        ),

        const SizedBox(height: 20),

        // Submit Button Shimmer
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
              key: _formKey,
              child: Column(
                children: [
                  _buildSecurityHeader(),
                  const SizedBox(height: 30),
                  _buildWarningCard(),
                  const SizedBox(height: 30),
                  _buildAgeToggle(),
                  const SizedBox(height: 30),
                  if (!_isMinor) ..._buildCitizenshipFields() else ..._buildStudentFields(),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityHeader() {
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
              Icons.verified_user_rounded,
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
                  'Secure Verification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your documents are encrypted and secure',
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

  Widget _buildWarningCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.1),
                  const Color(0xFFFF8E8E).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFE53E3E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Important Notice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please enter details accurately for verification.',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFE53E3E).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildAgeToggle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.cake_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'I am under 18 years old',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D1B69),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: _isMinor,
                    onChanged: (value) {
                      setState(() {
                        _isMinor = value;
                        _citizenshipNumber = '';
                        _citizenshipImage = null;
                        _schoolName = '';
                        _studentId = '';
                        _schoolIdImage = null;
                      });
                    },
                    activeColor: const Color(0xFF8A2BE2),
                    activeTrackColor: const Color(0xFF9370DB).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCitizenshipFields() {
    return [
      _buildFormField(
        controller: _citizenshipController,
        label: 'नागरिकता नम्बर',
        hint: '12-01-88-89707 or 12347',
        icon: Icons.badge_rounded,
        keyboardType: TextInputType.number,
        index: 0,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Citizenship number is required';
          }
          return null;
        },
        onSaved: (value) => _citizenshipNumber = value!,
      ),
      const SizedBox(height: 20),
      _buildFormField(
        controller: _issuedDateController,
        label: 'नागरिकता जारी मिति (वि.सं.)',
        hint: '२०७९/०५/१५',
        icon: Icons.calendar_today_rounded,
        keyboardType: TextInputType.number,
        inputFormatters: [_issuedDateFormatter],
        index: 1,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Issue date is required';
          }
          if (!_issuedDateFormatter.isFill()) {
            return 'Invalid date format';
          }
          // Add more validation logic here
          return null;
        },
        onSaved: (value) {
          if (value != null && value.isNotEmpty) {
            final formattedValue = value.replaceAll('/', '-');
            final nepaliDate = NepaliDateTime.tryParse(formattedValue);
            final adDate = nepaliDate?.toDateTime();
            _issuedDate = adDate;
          }
        },
      ),
      const SizedBox(height: 20),
      _buildFormField(
        controller: _issuedDistrictController,
        label: 'नागरिकता जारी जिल्ला',
        hint: 'Kaski',
        icon: Icons.location_city_rounded,
        index: 2,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Issue district is required';
          }
          return null;
        },
        onSaved: (value) => _issuedDistrict = value!,
      ),
      const SizedBox(height: 30),
      _buildImageUploadSection(
        title: 'Upload Citizenship Front Card',
        image: _citizenshipImage,
        isSchoolId: false,
      ),
    ];
  }

  List<Widget> _buildStudentFields() {
    return [
      _buildFormField(
        controller: TextEditingController(),
        label: 'School Name',
        hint: 'Enter your school name',
        icon: Icons.school_rounded,
        index: 0,
        validator: (value) => _isMinor && (value?.isEmpty ?? true) ? 'School name is required' : null,
        onSaved: (value) => _schoolName = value!,
      ),
      const SizedBox(height: 20),
      _buildFormField(
        controller: TextEditingController(),
        label: 'Student ID',
        hint: 'Enter your student ID',
        icon: Icons.perm_identity_rounded,
        index: 1,
        validator: (value) => _isMinor && (value?.isEmpty ?? true) ? 'Student ID is required' : null,
        onSaved: (value) => _studentId = value!,
      ),
      const SizedBox(height: 30),
      _buildImageUploadSection(
        title: 'Upload School ID Card',
        image: _schoolIdImage,
        isSchoolId: true,
      ),
    ];
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int index,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
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
                    inputFormatters: inputFormatters,
                    validator: validator,
                    onSaved: onSaved,
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

  Widget _buildImageUploadSection({
    required String title,
    required File? image,
    required bool isSchoolId,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
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
                color: const Color(0xFF9370DB).withOpacity(0.3),
                width: 2,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSchoolId ? Icons.school_rounded : Icons.badge_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D1B69),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (image != null)
                  AnimatedBuilder(
                    animation: _imageController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_imageController.value * 0.05),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9370DB).withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        onPressed: () => _pickImages(ImageSource.camera, isSchoolId),
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        onPressed: () => _pickImages(ImageSource.gallery, isSchoolId),
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? const Color(0xFF8A2BE2) : const Color(0xFF9370DB))
                .withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isPrimary
              ? const Color(0xFF8A2BE2)
              : Colors.white.withOpacity(0.9),
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF8A2BE2),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.bounceOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 60,
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
                  color: const Color(0xFF8A2BE2).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _saveForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Submit for Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                ).createShader(bounds),
                child: const Text(
                  'Uploading Document...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we process your document',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}