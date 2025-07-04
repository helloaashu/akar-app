import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PersonalInformationPage extends StatefulWidget {
  @override
  _PersonalInformationPageState createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage>
    with TickerProviderStateMixin {
  User? currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Purple Theme Colors
  static const Color primaryPurple = Color(0xFF6A4C93);
  static const Color deepPurple = Color(0xFF4A2C6A);
  static const Color lightPurple = Color(0xFF9B7EC7);
  static const Color gradientStart = Color(0xFF8B5CF6);
  static const Color gradientEnd = Color(0xFF3B82F6);
  static const Color cardBackground = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> getUserData() async {
    if (currentUser != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      return doc.data() ?? {};
    } else {
      throw Exception('User not logged in');
    }
  }

  String? getStringValue(dynamic value) {
    if (value == null) {
      return null;
    } else if (value is String) {
      return value;
    } else if (value is int || value is double || value is bool) {
      return value.toString();
    } else if (value is Timestamp) {
      final dateTime = value.toDate();
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } else {
      return 'Invalid data type';
    }
  }

  Widget buildEnhancedShimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradientStart.withOpacity(0.1),
            gradientEnd.withOpacity(0.05),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildShimmerHeader(),
              SizedBox(height: 24),
              buildShimmerSectionTitle(),
              ...List.generate(3, (index) => buildShimmerDetailCard(index)),
              SizedBox(height: 16),
              buildShimmerSectionTitle(),
              ...List.generate(3, (index) => buildShimmerDetailCard(index)),
              SizedBox(height: 16),
              buildShimmerSectionTitle(),
              ...List.generate(3, (index) => buildShimmerDetailCard(index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildShimmerHeader() {
    return Shimmer.fromColors(
      baseColor: lightPurple.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.8),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShimmerSectionTitle() {
    return Shimmer.fromColors(
      baseColor: lightPurple.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.8),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        margin: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget buildShimmerDetailCard(int index) {
    return Shimmer.fromColors(
      baseColor: lightPurple.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.8),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> editField(String field) async {
    String newValue = '';
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              "Edit $field",
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightPurple.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: "Enter new $field",
              hintStyle: TextStyle(color: textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: (value) {
              newValue = value;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: textSecondary,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text("Cancel"),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (newValue.isNotEmpty && currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .update({field: newValue});
                  setState(() {});
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text("Save"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientStart.withOpacity(0.1),
              gradientEnd.withOpacity(0.05),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradientStart, gradientEnd],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Hero(
                            tag: 'profile_icon',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),

                                  child: Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Manage your personal details',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return buildEnhancedShimmerPlaceholder();
                  }

                  if (snapshot.hasError) {
                    return Container(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: primaryPurple),
                            SizedBox(height: 16),
                            Text(
                              'Error fetching user data',
                              style: TextStyle(
                                fontSize: 18,
                                color: textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 64, color: primaryPurple),
                            SizedBox(height: 16),
                            Text(
                              'No user data found',
                              style: TextStyle(
                                fontSize: 18,
                                color: textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  var userData = snapshot.data!;
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EnhancedSectionTitle(
                              title: 'Personal Details',
                              icon: Icons.person,
                            ),
                            SizedBox(height: 16),
                            EnhancedDetailCard(
                              title: 'Full Name',
                              value: getStringValue(userData['name']),
                              icon: Icons.person_outline,
                              isEditable: true,
                              onEdit: () => editField('name'),
                            ),
                            EnhancedDetailCard(
                              title: 'Email',
                              value: getStringValue(userData['email']),
                              icon: Icons.email_outlined,
                              isEditable: true,
                              onEdit: () => editField('email'),
                            ),
                            EnhancedDetailCard(
                              title: 'Contact',
                              value: getStringValue(userData['contact']),
                              icon: Icons.phone_outlined,
                              isEditable: true,
                              onEdit: () => editField('contact'),
                            ),

                            SizedBox(height: 32),
                            EnhancedSectionTitle(
                              title: 'Address Details',
                              icon: Icons.location_on,
                            ),
                            SizedBox(height: 16),
                            EnhancedDetailCard(
                              title: 'Home Address',
                              value: getStringValue(userData['homeAddress']),
                              icon: Icons.home_outlined,
                              isEditable: true,
                              onEdit: () => editField('homeAddress'),
                            ),
                            EnhancedDetailCard(
                              title: 'Zip/Postal',
                              value: getStringValue(userData['postal_code']),
                              icon: Icons.local_post_office_outlined,
                              isEditable: true,
                              onEdit: () => editField('postal_code'),
                            ),
                            EnhancedDetailCard(
                              title: 'State',
                              value: getStringValue(userData['state']),
                              icon: Icons.map_outlined,
                              isEditable: true,
                              onEdit: () => editField('state'),
                            ),
                            EnhancedDetailCard(
                              title: 'Home Number',
                              value: getStringValue(userData['home_number']),
                              icon: Icons.phone_outlined,
                              isEditable: true,
                              onEdit: () => editField('home_number'),
                            ),

                            SizedBox(height: 32),
                            EnhancedSectionTitle(
                              title: 'Document Details',
                              icon: Icons.description,
                            ),
                            SizedBox(height: 16),
                            EnhancedDetailCard(
                              title: 'Citizenship (Front)',
                              value: getStringValue(userData['idImageURL']),
                              icon: Icons.image_outlined,
                              isImage: true,
                              isEditable: false,
                              onEdit: () {},
                            ),
                            EnhancedDetailCard(
                              title: 'Citizenship No.',
                              value: getStringValue(userData['citizenshipNumber']),
                              icon: Icons.badge_outlined,
                              isEditable: false,
                              onEdit: () {},
                            ),
                            EnhancedDetailCard(
                              title: 'Issued Date',
                              value: getStringValue(userData['issuedDate']),
                              icon: Icons.date_range_outlined,
                              isEditable: false,
                              onEdit: () {},
                            ),
                            EnhancedDetailCard(
                              title: 'Issued District',
                              value: getStringValue(userData['issuedDistrict']),
                              icon: Icons.location_city_outlined,
                              isEditable: false,
                              onEdit: () {},
                            ),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  EnhancedSectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _PersonalInformationPageState.gradientStart.withOpacity(0.1),
            _PersonalInformationPageState.gradientEnd.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _PersonalInformationPageState.lightPurple.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _PersonalInformationPageState.gradientStart,
                  _PersonalInformationPageState.gradientEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _PersonalInformationPageState.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedDetailCard extends StatefulWidget {
  final String title;
  final String? value;
  final IconData icon;
  final bool isImage;
  final bool isEditable;
  final VoidCallback onEdit;

  EnhancedDetailCard({
    required this.title,
    this.value,
    required this.icon,
    this.isImage = false,
    required this.isEditable,
    required this.onEdit,
  });

  @override
  _EnhancedDetailCardState createState() => _EnhancedDetailCardState();
}

class _EnhancedDetailCardState extends State<EnhancedDetailCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        },
        onTapUp: (_) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        },
        onTapCancel: () {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _PersonalInformationPageState.primaryPurple.withOpacity(0.1),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
            border: Border.all(
              color: _isHovered
                  ? _PersonalInformationPageState.lightPurple.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _PersonalInformationPageState.gradientStart.withOpacity(0.1),
                      _PersonalInformationPageState.gradientEnd.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: _PersonalInformationPageState.primaryPurple,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _PersonalInformationPageState.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    widget.isImage
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: widget.value ?? '',
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _PersonalInformationPageState.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _PersonalInformationPageState.primaryPurple,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _PersonalInformationPageState.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: _PersonalInformationPageState.textSecondary,
                          ),
                        ),
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Text(
                      widget.value ?? 'No data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.value != null
                            ? _PersonalInformationPageState.textPrimary
                            : _PersonalInformationPageState.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isEditable)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _PersonalInformationPageState.gradientStart,
                        _PersonalInformationPageState.gradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _PersonalInformationPageState.primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Colors.white),
                    onPressed: widget.onEdit,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}