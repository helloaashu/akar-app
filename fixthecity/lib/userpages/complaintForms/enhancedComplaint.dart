import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../Screens/mapscreen.dart';
import '../../widgets/complaint_form/form_sections/location_picker_section.dart';
import '../../widgets/dialogs/oops_dialog.dart';
import '../../widgets/dialogs/success_dialog.dart';
import '../services/preference_service.dart';
import 'basic_ai_form.dart';
import 'advanced_ai_form.dart';
import 'complaintWidgets/ai_mode_dialog.dart';

class EnhancedComplaintForm extends StatefulWidget {
  @override
  State<EnhancedComplaintForm> createState() => _EnhancedComplaintFormState();
}

class _EnhancedComplaintFormState extends State<EnhancedComplaintForm> with TickerProviderStateMixin {
  int selectedAIIndex = 0;
  LatLng? location;
  String? address;
  String? _category;
  String? _complaintType;
  String? _customCategory;
  String? _customIssueType;

  // Form data storage
  Map<String, dynamic> _basicFormData = {};
  Map<String, dynamic> _advancedFormData = {};

  // Form completion states
  bool _isBasicFormComplete = false;
  bool _isAdvancedFormComplete = false;
  bool _isLocationSelected = false;

  // Loading state for submission
  bool _isSubmitting = false;

  // Reset trigger - increment this to force forms to reset
  int _resetTrigger = 0;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _waveController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Initialize animations
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(Duration.zero, () async {
      bool shouldShow = await PreferenceService.shouldShowAIModePrompt();
      if (shouldShow) {
        await showAIModeDialog(context);
      }
    });
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        location = result['location'];
        address = result['address'];
        _isLocationSelected = true;
      });

      // Show success message with stunning top notification
      _showTopNotification(
        'Location selected: ${address ?? 'Unknown address'}',
        isSuccess: true,
      );
    }
  }

  // Handle Basic AI form data changes
  void _onBasicFormDataChanged(Map<String, dynamic> data) {
    setState(() {
      _basicFormData = data;
      _isBasicFormComplete = data['isFormComplete'] == true;
    });
  }

  // Handle Advanced AI form data changes
  void _onAdvancedFormDataChanged(Map<String, dynamic> data) {
    setState(() {
      _advancedFormData = data;
      _isAdvancedFormComplete = data['isFormComplete'] == true;
    });
  }

  // Handle Advanced AI form completion
  void _onAdvancedFormComplete() {
    // Scroll to location section or show helpful message
    _showTopNotification(
      'Great! Now select a location and submit your complaint.',
      isInfo: true,
    );
  }



  // Check if form can be submitted
  bool get _canSubmit {
    if (!_isLocationSelected) return false;

    if (selectedAIIndex == 0) {
      // Basic AI mode
      return _isBasicFormComplete;
    } else {
      // Advanced AI mode
      return _isAdvancedFormComplete;
    }
  }

  // Get current form data based on selected mode
  Map<String, dynamic> get _currentFormData {
    return selectedAIIndex == 0 ? _basicFormData : _advancedFormData;
  }

  // Handle form submission
  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare submission data
      final submissionData = {
        'formType': selectedAIIndex == 0 ? 'basic' : 'advanced',
        'location': {
          'coordinates': {
            'latitude': location!.latitude,
            'longitude': location!.longitude,
          },
          'address': address,
        },
        'formData': _currentFormData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // TODO: Replace with actual Firebase call
      await _submitToFirebase(submissionData);

      // Show success message
      if (context.mounted) {
        _showTopNotification(
          'Complaint submitted successfully!',
          isSuccess: true,
        );

        // Reset form or navigate away
        _resetForm();
      }

    } catch (e) {
      if (context.mounted) {
        _showTopNotification(
          'Submission failed: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Submit to Firebase
  Future<void> _submitToFirebase(Map<String, dynamic> data) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final status = doc.data()?['verificationStatus'] ?? 'pending';
      if (status != 'verified') {
        String message =
            'Please complete your profile and become a verified user to submit your complaint. This helps us better assist you.';
        showDialog(
          context: context,
          builder: (context) => OopsDialog(message: message),
        );
        _resetForm();
        return;
      }
    }

    try {
      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      // final complaintRef = FirebaseFirestore.instance.collection('complaints').doc();
      // final complaintId = complaintRef.id;

      final docRef = await FirebaseFirestore.instance
          .collection('complaints').doc();


      final String finalCategory =
      _category == 'Other' ? _customCategory ?? 'Other' : _category ?? 'Unknown';
      final String finalComplaintType =
      _category == 'Other' || _complaintType == 'Other'
          ? _customIssueType ?? 'Other'
          : _complaintType ?? 'Unknown';

      // Upload images first (if any) and get URLs
      List<String> imageUrls = [];
      if (data['formData']['images'] != null && (data['formData']['images'] as List).isNotEmpty) {
        imageUrls = await _uploadImagesToStorage(data['formData']['images']);
      }

      // Prepare base complaint data for both modes
      Map<String, dynamic> complaintData = {
        // Essential fields for all complaints
        'formType': data['formType'],
        'ticketNumber': docRef.id,
        'status': 'In Progress', // Default status as requested
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'timestamp':FieldValue.serverTimestamp(),
        'userID': currentUser?.uid,

        // Location data
        'location': location != null
            ? GeoPoint(location!.latitude, location!.longitude)
            : null,
        'address': data['location']['address'],

        // Images
        'images': imageUrls,
        'imageCount': imageUrls.length,

        // Common form fields (available in both modes)
        'title': data['formData']['title'] ?? '',
        'description': data['formData']['description'] ?? '',
        'category': data['formData']['category'] ?? '',
        'severity': data['formData']['severity'] ?? '',
        'department': data['formData']['department'] ?? '',

        // Priority calculation
        'priority': _calculatePriority(data['formData']),
        'estimatedResolutionTime': _estimateResolutionTime(data['formData']),
      };

      // Add mode-specific fields
      if (data['formType'] == 'advanced') {
        // Advanced AI specific fields
        complaintData.addAll({
          'aiAnalysis': data['formData']['aiAnalysis'] ?? '',
          'aiSuggestions': data['formData']['aiSuggestions'] ?? '',
          'hasAiAnalysis': data['formData']['hasAiAnalysis'] ?? false,

          // Detailed AI analysis data
          'analysisData': data['formData']['analysisData'] != null ? {
            'category': data['formData']['analysisData'].category,
            'severity': data['formData']['analysisData'].severity,
            'department': data['formData']['analysisData'].department,
            'explanation': data['formData']['analysisData'].explanation,
            'suggestions': data['formData']['analysisData'].suggestions,
            'confidence': data['formData']['analysisData'].confidence,
            'isRelevant': data['formData']['analysisData'].isRelevant,
          } : null,
        });
      } else {
        // Basic AI specific fields (if any)
        complaintData.addAll({
          'hasAiAnalysis': false,
          'analysisData': null,
          'aiAnalysis': '',
          'aiSuggestions': '',
        });
      }

      // Add to Firestore 'complaints' collection
      await docRef.set(complaintData);
      SuccessDialog.show(context, docRef.id);

      print('Complaint submitted successfully with ID: ${docRef.id}');

    } catch (e) {
      print('Firebase submission error: $e');
      throw Exception('Failed to submit complaint to database: $e');
    }
  }

  // Upload images to Firebase Storage and return URLs
  Future<List<String>> _uploadImagesToStorage(List images) async {
    List<String> imageUrls = [];

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String userId = currentUser?.uid ?? 'anonymous';
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      for (int i = 0; i < images.length; i++) {
        // Create unique filename
        String fileName = 'complaints/$userId/${timestamp}_image_$i.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);

        // Upload file
        UploadTask uploadTask = ref.putFile(File(images[i].path));
        TaskSnapshot snapshot = await uploadTask;

        // Get download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);

        print('Image ${i + 1} uploaded successfully: $downloadUrl');
      }

    } catch (e) {
      print('Image upload error: $e');
      // Continue without images rather than failing the entire submission
      _showTopNotification(
        'Images could not be uploaded, but complaint was submitted',
        isWarning: true,
      );
    }

    return imageUrls;
  }

  // Calculate priority based on AI analysis or form data
  String _calculatePriority(Map<String, dynamic> formData) {
    // Priority from AI analysis (Advanced mode)
    if (formData['analysisData'] != null) {
      int severity = formData['analysisData'].severity ?? 1;
      if (severity >= 4) return 'High';
      if (severity >= 3) return 'Medium';
      return 'Low';
    }

    // Priority from severity text (Basic mode)
    String severityText = (formData['severity'] ?? '').toLowerCase();
    if (severityText.contains('high') || severityText.contains('urgent') || severityText.contains('emergency')) {
      return 'High';
    } else if (severityText.contains('medium') || severityText.contains('moderate')) {
      return 'Medium';
    }

    return 'Low'; // Default
  }

  // Estimate resolution time based on category and severity
  String _estimateResolutionTime(Map<String, dynamic> formData) {
    String category = (formData['category'] ?? '').toLowerCase();
    String severity = (formData['severity'] ?? '').toLowerCase();

    // Emergency/High priority cases
    if (severity.contains('high') || severity.contains('urgent') || severity.contains('emergency') || severity.contains('safety')) {
      return '24-48 hours';
    }

    // Category-based estimates
    if (category.contains('pothole') || category.contains('road')) {
      return severity.contains('medium') ? '3-5 days' : '5-7 days';
    } else if (category.contains('lighting') || category.contains('streetlight')) {
      return '1-3 days';
    } else if (category.contains('drainage') || category.contains('water')) {
      return '5-10 days';
    } else if (category.contains('traffic') || category.contains('signal')) {
      return '2-4 days';
    } else if (category.contains('waste') || category.contains('garbage')) {
      return '1-2 days';
    }

    return '5-14 days'; // Default estimate
  }

  // Reset form after successful submission
  void _resetForm() {
    setState(() {
      _basicFormData = {};
      _advancedFormData = {};
      _isBasicFormComplete = false;
      _isAdvancedFormComplete = false;
      _isLocationSelected = false;
      location = null;
      address = null;
      selectedAIIndex = 0;

      // Increment reset trigger to force forms to reset
      _resetTrigger++;
    });
  }

  // Build submission status widget
  Widget _buildSubmissionStatus() {
    if (selectedAIIndex == 0) {
      // Basic AI mode status
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isBasicFormComplete ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isBasicFormComplete ? Colors.green.shade300 : Colors.orange.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isBasicFormComplete ? Icons.check_circle : Icons.pending,
              color: _isBasicFormComplete ? Colors.green.shade700 : Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isBasicFormComplete
                    ? 'Basic form completed ✓'
                    : 'Complete the basic form above',
                style: TextStyle(
                  color: _isBasicFormComplete ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Advanced AI mode status
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isAdvancedFormComplete ? Colors.green.shade50 : Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isAdvancedFormComplete ? Colors.green.shade300 : Colors.purple.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isAdvancedFormComplete ? Icons.check_circle : Icons.psychology,
              color: _isAdvancedFormComplete ? Colors.green.shade700 : Colors.purple.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isAdvancedFormComplete
                    ? 'AI analysis completed ✓'
                    : 'Upload photos and complete AI analysis above',
                style: TextStyle(
                  color: _isAdvancedFormComplete ? Colors.green.shade700 : Colors.purple.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Build location status widget
  Widget _buildLocationStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isLocationSelected ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isLocationSelected ? Colors.green.shade300 : Colors.blue.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isLocationSelected ? Icons.check_circle : Icons.location_on,
            color: _isLocationSelected ? Colors.green.shade700 : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isLocationSelected
                  ? 'Location selected ✓'
                  : 'Select location Above',
              style: TextStyle(
                color: _isLocationSelected ? Colors.green.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // AI Mode Toggle
                        Center(
                          child: ToggleSwitch(
                            minWidth: MediaQuery.of(context).size.width / 2.3,
                            minHeight: 48,
                            initialLabelIndex: selectedAIIndex,
                            totalSwitches: 2,
                            cornerRadius: 20.0,
                            labels: ['Basic AI', '  Advanced AI'],
                            icons: [FontAwesomeIcons.microchip, FontAwesomeIcons.robot],
                            activeFgColor: Colors.white,
                            inactiveFgColor: Colors.white,
                            inactiveBgColor: Colors.grey.shade400,
                            activeBgColors: [
                              [Colors.blue],
                              [Colors.deepPurple]
                            ],
                            onToggle: (index) {
                              setState(() {
                                selectedAIIndex = index!;
                              });
                            },
                          ),
                        ),

                        SizedBox(height: 16),

                        // Dynamic AI Form
                        IndexedStack(
                          index: selectedAIIndex,
                          children: [
                            BasicAIForm(
                              key: ValueKey('basic_$_resetTrigger'), // Changes when reset
                              onFormDataChanged: _onBasicFormDataChanged,
                              resetTrigger: _resetTrigger,
                            ),
                            AdvancedAIForm(
                              key: ValueKey('advanced_$_resetTrigger'), // Changes when reset
                              onFormDataChanged: _onAdvancedFormDataChanged,
                              onFormComplete: _onAdvancedFormComplete,
                              resetTrigger: _resetTrigger,
                            ),
                          ],
                        ),

                        // Form completion status
                        _buildSubmissionStatus(),

                        SizedBox(height: 16),

                        // Location Picker
                        LocationPickerSection(
                          location: location,
                          address: address,
                          onSelectLocation: _selectLocation,
                        ),

                        // Location status
                        _buildLocationStatus(),

                        SizedBox(height: 20),

                        // Submit Button
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: 56,
                          decoration: _isSubmitting
                              ? BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600,
                                Colors.orange.shade400,
                              ],
                              stops: [0.0, 0.5, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                              : null,
                          child: ElevatedButton(
                            onPressed: _canSubmit && !_isSubmitting ? _handleSubmit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSubmitting
                                  ? Colors.transparent
                                  : (_canSubmit ? Colors.deepPurpleAccent : Colors.grey.shade400),
                              foregroundColor: Colors.white,
                              elevation: _canSubmit && !_isSubmitting ? 4 : 0,
                              shadowColor: _isSubmitting ? Colors.transparent : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? _buildSubmittingAnimation()
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Submit Complaint',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Submit requirements info
                        if (!_canSubmit)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getSubmitRequirementsText(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // Method to show stunning top notifications
  void _showTopNotification(String message, {bool isSuccess = false, bool isError = false, bool isWarning = false, bool isInfo = false}) {
    if (!mounted) return;

    Widget notification;

    if (isError) {
      notification = CustomSnackBar.error(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
        // icon: Icon(
        //   Icons.error_outline,
        //   color: Colors.white,
        //   size: 28,
        // ),
      );
    } else if (isWarning) {
      notification = CustomSnackBar.info(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(12),
        // icon: Icon(
        //   Icons.warning_amber_outlined,
        //   color: Colors.white,
        // //   size: 28,
        // ),
      );
    } else if (isInfo) {
      notification = CustomSnackBar.info(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(12),
        // icon: Icon(
        //   Icons.info_outline,
        //   color: Colors.white,
        //   size: 28,
        // ),
      );
    } else {
      // Success notification
      notification = CustomSnackBar.success(
        message: message,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.green.shade600,
        borderRadius: BorderRadius.circular(12),
        // icon: Icon(
        //   Icons.check_circle_outline,
        //   color: Colors.white,
        //   size: 28,
        // ),
      );
    }

    showTopSnackBar(
      Overlay.of(context),
      notification,
      animationDuration: const Duration(milliseconds: 1000),
      reverseAnimationDuration: const Duration(milliseconds: 600),
      displayDuration: const Duration(seconds: 4),
      dismissType: DismissType.onTap,
    );
  }

  // Build stunning submitting animation
  Widget _buildSubmittingAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotationController,
        _scaleController,
        _waveController,
      ]),
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing outer circle
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 2,
                  ),
                ),
                child: Center(
                  // Rotating inner elements
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Animated text with scale effect
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Submitting...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Animated wave dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      double delay = index * 0.2;
                      return AnimatedBuilder(
                        animation: _waveAnimation,
                        builder: (context, child) {
                          double animationValue = (_waveAnimation.value - delay).clamp(0.0, 1.0);
                          return Container(
                            margin: const EdgeInsets.only(right: 2, top: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                0.3 + (animationValue * 0.7),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Secondary pulsing element
            Transform.scale(
              scale: _pulseAnimation.value * 0.8,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getSubmitRequirementsText() {
    List<String> missing = [];

    if (selectedAIIndex == 0 && !_isBasicFormComplete) {
      missing.add('complete basic form');
    } else if (selectedAIIndex == 1 && !_isAdvancedFormComplete) {
      missing.add('complete AI analysis');
    }

    if (!_isLocationSelected) {
      missing.add('select location');
    }

    if (missing.isEmpty) {
      return 'Ready to submit!';
    }

    return 'Please ${missing.join(' and ')} to submit your complaint.';
  }
}