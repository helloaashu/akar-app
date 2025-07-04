import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import '../../widgets/models/road_issue_analysis.dart';
import '../../widgets/services/ai_services.dart';

class AdvancedAIForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onFormDataChanged;
  final VoidCallback? onFormComplete;
  final int? resetTrigger; // Add reset trigger parameter

  const AdvancedAIForm({
    super.key,
    this.onFormDataChanged,
    this.onFormComplete,
    this.resetTrigger, // Add reset trigger
  });

  @override
  State<AdvancedAIForm> createState() => _AdvancedAIFormState();
}

class _AdvancedAIFormState extends State<AdvancedAIForm> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Text Controllers for form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _severityController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _aiAnalysisController = TextEditingController();
  final TextEditingController _aiSuggestionsController = TextEditingController();

  List<XFile> _selectedImages = [];
  RoadIssueAnalysis? _analysis;
  bool _isAnalyzing = false;
  bool _hasUserDecided = false;
  bool _showFormFields = false;
  bool _isFormComplete = false; // New state to track form completion
  int? _lastResetTrigger; // Track last reset trigger value

  @override
  void initState() {
    super.initState();
    // Initialize clean state
    _clearFormFields();
    _lastResetTrigger = widget.resetTrigger;
  }

  @override
  void didUpdateWidget(AdvancedAIForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if reset trigger changed
    if (widget.resetTrigger != null &&
        widget.resetTrigger != _lastResetTrigger) {
      _lastResetTrigger = widget.resetTrigger;

      // Reset the form
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetFormCompletely();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _severityController.dispose();
    _departmentController.dispose();
    _aiAnalysisController.dispose();
    _aiSuggestionsController.dispose();
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

  // Get form data as Map
  Map<String, dynamic> getFormData() {
    return {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _categoryController.text,
      'severity': _severityController.text,
      'department': _departmentController.text,
      'aiAnalysis': _aiAnalysisController.text,
      'aiSuggestions': _aiSuggestionsController.text,
      'images': _selectedImages,
      'analysisData': _analysis,
      'hasAiAnalysis': _hasUserDecided && _analysis?.isRelevant == true,
      'isFormComplete': _isFormComplete, // Add completion status
    };
  }

  // Check if form is valid and complete
  bool _isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  // Notify parent of form data changes
  void _notifyFormDataChanged() {
    if (widget.onFormDataChanged != null) {
      widget.onFormDataChanged!(getFormData());
    }
  }

  //request permission for image picking
  Future<void> _requestPermissionAndPickImage() async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      _showSourcePicker();
    } else if (cameraStatus.isPermanentlyDenied) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Camera Permission Required"),
          content: const Text(
            "Camera access is required to upload images.\n\nPlease enable it from app settings.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
    } else {
      _showTopNotification(
        "Camera permission is required.",
        isError: true,
      );
    }
  }

  Future<void> _showSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.blue),
              title: const Text('Take a Photo'),
              subtitle: const Text('Capture image with camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from device storage'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickAndAnalyzeImage(source);
    }
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return;

      // Check if we can add more images
      if (_selectedImages.length >= 3) {
        _showTopNotification(
          'You can only select up to 3 images in total.',
          isWarning: true,
        );
        return;
      }

      // Add image to the list
      setState(() {
        _selectedImages.add(photo);
      });

      // If this is the first image, analyze it
      if (_selectedImages.length == 1 && !_hasUserDecided) {
        await _analyzeImage(File(photo.path));
      }

      _notifyFormDataChanged();
    } catch (e) {
      _showTopNotification(
        'Error picking image: $e',
        isError: true,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty) {
        _analysis = null;
        _hasUserDecided = false;
        _showFormFields = false;
        _isFormComplete = false;
        _clearFormFields();
      }
    });
    _notifyFormDataChanged();
  }

  void _clearFormFields() {
    _titleController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _severityController.clear();
    _departmentController.clear();
    _aiAnalysisController.clear();
    _aiSuggestionsController.clear();
  }

  // Public method to reset the entire form (can be called from parent)
  void resetForm() {
    _resetFormCompletely();
  }

  // Complete form reset method
  void _resetFormCompletely() {
    if (mounted) {
      setState(() {
        _selectedImages.clear();
        _analysis = null;
        _hasUserDecided = false;
        _showFormFields = false;
        _isAnalyzing = false;
        _isFormComplete = false;
        _clearFormFields();
      });
      _notifyFormDataChanged();
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _analysis = null;
    });

    try {
      final analysis = await GeminiService.analyzeRoadImage(imageFile);
      setState(() {
        _analysis = analysis;
      });
    } catch (e) {
      _showTopNotification(
        'AI Analysis failed: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _acceptAiSuggestions() {
    if (_analysis != null && _analysis!.isRelevant) {
      setState(() {
        _hasUserDecided = true;
        _showFormFields = true;

        // Pre-fill form fields with AI analysis
        _categoryController.text = _analysis!.category;
        _severityController.text = _getSeverityText(_analysis!.severity);
        _departmentController.text = _analysis!.department;
        _aiAnalysisController.text = _analysis!.explanation;
        _aiSuggestionsController.text = _analysis!.suggestions.join(', ');

        // Generate a title based on category and severity
        _titleController.text = '${_analysis!.category} Issue - ${_getSeverityText(_analysis!.severity)}';

        // Pre-fill description with AI analysis
        _descriptionController.text = _analysis!.explanation;
      });

      _notifyFormDataChanged();

      // Show success message
      _showTopNotification(
        'AI analysis accepted! Complete the remaining fields below.',
        isSuccess: true,
      );
    }
  }

  void _navigateToBasicForm() {
    // Navigate to basic form or trigger parent widget to switch modes
    Navigator.pop(context, 'switch_to_basic');

    _showTopNotification(
      'Switching to Basic Form mode...',
      isInfo: true,
    );
  }

  void _resetForm() {
    _resetFormCompletely();

    // Show reset confirmation
    _showTopNotification(
      'Form has been reset',
      isInfo: true,
    );
  }

  // Handle form completion
  void _markFormComplete() {
    if (_isFormValid()) {
      setState(() {
        _isFormComplete = true;
      });
      _notifyFormDataChanged();

      // Notify parent that form is complete
      if (widget.onFormComplete != null) {
        widget.onFormComplete!();
      }

      // Show success message
      _showTopNotification(
        'Form completed! You can now submit the complaint.',
        isSuccess: true,
      );
    }
  }

  Widget _buildFormFields() {
    if (!_showFormFields) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.indigo.shade600, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Complete Your Complaint',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Form completion indicator
                    if (_isFormComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Complete',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Complaint Title *',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onChanged: (_) => _notifyFormDataChanged(),
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onChanged: (_) => _notifyFormDataChanged(),
                ),
                const SizedBox(height: 16),

                // AI Analysis Results (Read-only)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'AI Analysis Results',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category (Read-only)
                      TextFormField(
                        controller: _categoryController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Severity (Read-only)
                      TextFormField(
                        controller: _severityController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Severity',
                          prefixIcon: const Icon(Icons.priority_high),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Department (Read-only)
                      TextFormField(
                        controller: _departmentController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Responsible Department',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Done/Complete Button (replaces Submit)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isFormComplete ? null : _markFormComplete,
                    icon: Icon(
                      _isFormComplete ? Icons.check_circle : Icons.done,
                      size: 24,
                    ),
                    label: Text(
                      _isFormComplete ? 'Form Completed ✓' : 'Mark as Complete',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormComplete
                          ? Colors.green.shade600
                          : Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isFormComplete
                              ? 'Form is ready! Add the Location and hit submit button.'
                              : 'Complete this form, then add location then hit submit ',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Reset Form'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildAiAnalysisSection() {
    if (_isAnalyzing) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          elevation: 3,
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'AI is analyzing your image...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_analysis == null) return const SizedBox.shrink();

    if (!_analysis!.isRelevant) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          elevation: 3,
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Image Not Suitable for AI Analysis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'The AI couldn\'t identify a relevant community issue in this image.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Possible reasons:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text('• Image quality is too low or blurry'),
                const Text('• No clear infrastructure issues visible'),
                const Text('• Image shows irrelevant content'),
                const Text('• Lighting conditions are poor'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _removeImage(0);
                        },
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expanded(
                    //   child: OutlinedButton.icon(
                    //     onPressed: _navigateToBasicForm,
                    //     icon: const Icon(Icons.edit_note, size: 20),
                    //     label: const Text('Basic Form'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Colors.blue.shade700,
                    //       side: BorderSide(color: Colors.blue.shade300),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Analysis Complete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_analysis!.confidence * 100).toStringAsFixed(0)}% confident',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Category', _analysis!.category),
              _buildInfoRow('Severity', _getSeverityText(_analysis!.severity)),
              _buildInfoRow('Department', _analysis!.department),
              const SizedBox(height: 8),
              const Text(
                'Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                _analysis!.explanation,
                style: const TextStyle(fontSize: 14),
              ),
              if (_analysis!.suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'AI Suggestions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                ...(_analysis!.suggestions.take(3).map((s) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                ))),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _acceptAiSuggestions,
                      icon: const Icon(Icons.smart_toy, size: 20),
                      label: const Text('Accept Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expanded(
                  //   child: OutlinedButton.icon(
                  //     onPressed: _navigateToBasicForm,
                  //     icon: const Icon(Icons.edit_note, size: 20),
                  //     label: const Text('Use Basic Form'),
                  //     style: OutlinedButton.styleFrom(
                  //       foregroundColor: Colors.blue.shade700,
                  //       side: BorderSide(color: Colors.blue.shade300),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSeverityText(int severity) {
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
        return 'Unknown';
    }
  }

  Widget _buildImagePickerSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enhanced AI Photo Upload Card
        if (_selectedImages.isEmpty) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Card(
              elevation: 8,
              shadowColor: Colors.indigo.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo.shade50,
                      Colors.blue.shade50,
                      Colors.purple.shade50,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AI Brain Animation Container
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.indigo.shade400,
                              Colors.purple.shade400,
                              Colors.blue.shade400,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Inner pulse ring
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            // AI Brain Icon
                            const Icon(
                              Icons.psychology,
                              size: 36,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main Title
                      Text(
                        '🧠 AI-Powered Analysis',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Upload photos of community issues and let our AI instantly analyze and categorize them',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Features Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeatureItem(
                            icon: Icons.camera_alt,
                            label: 'Smart\nCapture',
                            color: Colors.green,
                          ),
                          _buildFeatureItem(
                            icon: Icons.auto_awesome,
                            label: 'AI\nAnalysis',
                            color: Colors.purple,
                          ),
                          _buildFeatureItem(
                            icon: Icons.category,
                            label: 'Auto\nCategory',
                            color: Colors.orange,
                          ),
                          _buildFeatureItem(
                            icon: Icons.speed,
                            label: 'Instant\nResults',
                            color: Colors.blue,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Upload Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _requestPermissionAndPickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: Colors.indigo.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.indigo.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.indigo.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Upload up to 3 photos. First photo is required for AI analysis.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.indigo.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
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
        ] else ...[
          // Compact version when images are selected
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.purple.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'AI Analysis Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_selectedImages.length}/3 photos uploaded',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.indigo.shade300,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: _selectedImages.length < 3
                      ? _requestPermissionAndPickImage
                      : null,
                  icon: Icon(
                    Icons.add_a_photo,
                    color: _selectedImages.length < 3
                        ? Colors.indigo.shade700
                        : Colors.grey.shade400,
                  ),
                  tooltip: _selectedImages.length < 3
                      ? 'Add more photos'
                      : 'Maximum 3 photos',
                ),
              ),
            ],
          ),
        ],

        // Selected images grid
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 120,
                  child: Stack(
                    children: [
                      // Image Container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        ),
                      ),

                      // Remove Button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),

                      // AI Badge for first image
                      if (index == 0 && _analysis != null && _analysis!.isRelevant)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade500, Colors.teal.shade500],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Image number indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade600,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Image Upload Tips (shown when images are present)
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Include multiple angles for better AI analysis',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Advanced AI Mode",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Upload photos and let AI analyze your community issues automatically",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Image picker section
        _buildImagePickerSection(),

        // AI Analysis section
        if (_selectedImages.isNotEmpty && !_hasUserDecided)
          _buildAiAnalysisSection(),

        // Form fields (shown after accepting AI analysis)
        _buildFormFields(),
      ],
    );
  }
}