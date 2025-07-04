import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

// Import all components including new AI components
import '../Screens/mapscreen.dart';
import '../widgets/complaint_form/form_sections/category_section.dart';
import '../widgets/complaint_form/form_sections/issue_type_section.dart';
import '../widgets/complaint_form/form_sections/nature_complaint_section.dart';
import '../widgets/complaint_form/form_sections/complaint_details_section.dart';
//import '../widgets/complaint_form/form_sections/ai_image_picker_section.dart';
import '../widgets/complaint_form/form_sections/location_picker_section.dart';
import '../widgets/dialogs/oops_dialog.dart';
import '../widgets/dialogs/success_dialog.dart';
import '../widgets/models/road_issue_analysis.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/utils/category_mapper.dart';
import '../widgets/utils/image_utils.dart';

class RegisterComplaintForm extends StatefulWidget {
  const RegisterComplaintForm({super.key});

  @override
  State<RegisterComplaintForm> createState() => _RegisterComplaintFormState();
}

class _RegisterComplaintFormState extends State<RegisterComplaintForm> {
  // Form state variables
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _selectedImages = [];

  bool _aiPopulated = false;
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Controllers
  final TextEditingController _complaintDetailsController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Form field values
  LatLng? location;
  String? address;
  String? _category;
  String? _complaintType;
  String? _customCategory;
  String? _customIssueType;
  String? _natureOfComplaint;
  String _landmark = '';
  String _streetName = '';

  // AI Analysis
  RoadIssueAnalysis? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _complaintDetailsController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
  }

  void _handleAiAnalysis(RoadIssueAnalysis analysis) {
    if (analysis.isRelevant) {
      setState(() {
        _aiAnalysis = analysis;
        _aiPopulated = true;

        // Map AI category to form category
        _category = CategoryMapper.mapAiCategoryToFormCategory(analysis.category);

        // Map AI issue to form issue type
        _complaintType = CategoryMapper.mapAiIssueToFormIssue(_category!, analysis.explanation);

        // Set nature of complaint based on severity
        _natureOfComplaint = _getSeverityMapping(analysis.severity);

        // Pre-fill complaint details with AI analysis
        _complaintDetailsController.text = analysis.explanation;

        // If suggestions exist, append them to details
        if (analysis.suggestions.isNotEmpty) {
          _complaintDetailsController.text += '\n\nAdditional information:\n';
          for (final suggestion in analysis.suggestions) {
            _complaintDetailsController.text += '- $suggestion\n';
          }
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI has pre-filled the form based on your image!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _getSeverityMapping(int severity) {
    switch (severity) {
      case 1:
      case 2:
        return 'Low (General maintenance request)';
      case 3:
        return 'Medium (Significant inconvenience)';
      case 4:
      case 5:
        return 'High (Major disruption, safety risk)';
      default:
        return 'Medium (Significant inconvenience)';
    }
  }
//pick location
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
      });
    }
  }

  void _addImage(XFile image) {
    setState(() {
      _selectedImages!.add(image);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages!.removeAt(index);
      // If removing the first image that was analyzed, clear AI data
      if (index == 0 && _aiPopulated) {
        _clearAiData();
      }
    });
  }

  void _clearAiData() {
    setState(() {
      _aiPopulated = false;
      _aiAnalysis = null;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSubmitting = true;
      });

      // Check verification status
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
        // Create complaint document
        final complaintRef = FirebaseFirestore.instance.collection('complaints').doc();
        final complaintId = complaintRef.id;

        // Upload images
        List<String> imageUrls = [];
        if (_selectedImages!.isNotEmpty) {
          imageUrls = await ImageUtils.uploadImages(_selectedImages!, complaintId);
        }

        final String finalCategory =
        _category == 'Other' ? _customCategory ?? 'Other' : _category ?? 'Unknown';
        final String finalComplaintType =
        _category == 'Other' || _complaintType == 'Other'
            ? _customIssueType ?? 'Other'
            : _complaintType ?? 'Unknown';

        // Save complaint data with AI metadata if available
        final complaintData = {
          'userID': currentUser?.uid,
          'ticketNumber': complaintRef.id,
          'category': finalCategory,
          'complaintType': finalComplaintType,
          'natureOfComplaint': _natureOfComplaint,
          'area': addressController.text,
          'landmark': _landmark,
          'streetName': _streetName,
          'complaintDetails': _complaintDetailsController.text,
          'location': location != null
              ? GeoPoint(location!.latitude, location!.longitude)
              : null,
          'address': address,
          'timestamp': FieldValue.serverTimestamp(),
          'images': imageUrls,
          'status': 'In Progress',
        };

        // Add AI analysis data if available
        if (_aiAnalysis != null && _aiPopulated) {
          complaintData['aiAnalysis'] = {
            'used': true,
            'confidence': _aiAnalysis!.confidence,
            'department': _aiAnalysis!.department,
            'originalCategory': _aiAnalysis!.category,
            'severity': _aiAnalysis!.severity,
          };
        } else {
          complaintData['aiAnalysis'] = {'used': false};
        }

        await complaintRef.set(complaintData);

        // Show success dialog
        SuccessDialog.show(context, complaintRef.id);
        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedImages!.clear();
      _complaintDetailsController.clear();
      addressController.clear();
      _category = null;
      _complaintType = null;
      _natureOfComplaint = null;
      location = null;
      address = null;
      _isSubmitting = false;
      _aiPopulated = false;
      _aiAnalysis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double formWidth = screenWidth > 600 ? 600 : screenWidth * 0.9;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: formWidth),
                  child: _isLoading
                      ? const ShimmerLoading()
                      : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Info banner about AI
                        Card(
                          color: Colors.blue.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Take a photo first! Our AI will analyze it and auto-fill the form for you.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // AI-Enhanced Image Picker Section
                        // AiImagePickerSection(
                        //   selectedImages: _selectedImages,
                        //   onImageAdded: _addImage,
                        //   onRemoveImage: _removeImage,
                        //   onAnalysisComplete: _handleAiAnalysis,
                        //   picker: _picker,
                        // ),

                        const SizedBox(height: 20),

                        // Show divider if AI populated
                        if (_aiPopulated) ...[
                          const Divider(),
                          const Text(
                            'Form auto-filled by AI. You can modify any field:',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category Section
                        CategorySection(
                          category: _category,
                          customCategory: _customCategory,
                          onCategoryChanged: (value) {
                            setState(() {
                              _category = value;
                              _complaintType = null;
                              _customCategory = null;
                              _customIssueType = null;
                            });
                          },
                          onCustomCategoryChanged: (value) {
                            setState(() {
                              _customCategory = value;
                            });
                          },
                        ),

                        const SizedBox(height: 17),

                        // Issue Type Section
                        IssueTypeSection(
                          category: _category,
                          complaintType: _complaintType,
                          customIssueType: _customIssueType,
                          onComplaintTypeChanged: (value) {
                            setState(() {
                              _complaintType = value;
                              if (value == 'Other') {
                                _customIssueType = null;
                              }
                            });
                          },
                          onCustomIssueTypeChanged: (value) {
                            setState(() {
                              _customIssueType = value;
                            });
                          },
                        ),

                        const SizedBox(height: 17),

                        // Nature of Complaint Section
                        NatureComplaintSection(
                          natureOfComplaint: _natureOfComplaint,
                          onChanged: (value) {
                            setState(() {
                              _natureOfComplaint = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Complaint Details Section
                        ComplaintDetailsSection(
                          controller: _complaintDetailsController,
                        ),

                        const SizedBox(height: 20),

                        // Location Picker Section
                        // LocationPickerSection(
                        //   location: location,
                        //   address: address,
                        //   onSelectLocation: _selectLocation,
                        // ),

                        const SizedBox(height: 20.0),

                        // Submit Button
                        Center(
                          child: SizedBox(
                            width: 120,
                            height: 49,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSubmitting
                                    ? Colors.greenAccent
                                    : Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }
}