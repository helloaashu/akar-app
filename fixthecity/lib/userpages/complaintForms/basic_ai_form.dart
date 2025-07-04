

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../Home/widgets/Multi-model.dart' as model;

class BasicAIForm extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onFormDataChanged;
  final int resetTrigger;

  const BasicAIForm({super.key, required this.onFormDataChanged, required this.resetTrigger});

  @override
  State<BasicAIForm> createState() => _BasicAIFormState();
}

class _BasicAIFormState extends State<BasicAIForm> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  img.Image? _decodedImage;
  List<model.Detection> _detections = [];
  bool _isAnalyzing = false;
  String? _errorMessage;
  bool _showNoDetectionWarning = false;
  String _processingStep = "";
  bool _isFormAccepted = false;

  // Form controllers
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _confidenceController = TextEditingController();
  final TextEditingController _severityController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  model.Detection? _selectedDetection;

  final List<String> modelPaths = [
    'assets/model/abhi.onnx',
    'assets/model/yolov5_model.onnx',
  ];

  final List<List<String>> modelLabels = [
    ['potholes', 'cracks', 'open_manhole'],
    ['Animal', 'Traffic Light', 'Waste Container'],
  ];

  @override
  void initState() {
    super.initState();
    // Defer the reset until after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetFormIfNeeded();
    });
  }

  @override
  void didUpdateWidget(BasicAIForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetTrigger != oldWidget.resetTrigger) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetFormIfNeeded();
      });
    }
  }

  void _resetFormIfNeeded() {
    setState(() {
      _image = null;
      _decodedImage = null;
      _detections.clear();
      _selectedDetection = null;
      _isFormAccepted = false;
      _errorMessage = null;
      _showNoDetectionWarning = false;
    });

    // Clear form data separately to avoid nested setState
    _clearFormDataSilently();

    // Update parent after clearing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFormData();
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _confidenceController.dispose();
    _severityController.dispose();
    _departmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Method to prefill form data based on detection
  void _prefillFormData(model.Detection detection) {
    final category = _mapLabelToCategory(detection.label);
    final severity = _mapCategoryToSeverity(category);
    final department = _mapCategoryToDepartment(category);

    setState(() {
      _categoryController.text = category;
      _confidenceController.text = "${(detection.confidence * 100).toStringAsFixed(1)}%";
      _severityController.text = severity;
      _departmentController.text = department;
      _descriptionController.text = _generateDescription(detection);
    });

    // Safely update parent after state change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateFormData();
      }
    });
  }

  // Method to clear all form data
  void _clearFormData() {
    setState(() {
      _categoryController.clear();
      _confidenceController.clear();
      _severityController.clear();
      _departmentController.clear();
      _descriptionController.clear();
      _selectedDetection = null;
    });

    // Update parent with cleared data
    _updateFormData();
  }

  // Method to clear form data without triggering parent update (for reset)
  void _clearFormDataSilently() {
    _categoryController.clear();
    _confidenceController.clear();
    _severityController.clear();
    _departmentController.clear();
    _descriptionController.clear();
    _selectedDetection = null;
  }

  // Method to update form data in parent
  void _updateFormData() {
    // Avoid calling during build phase
    if (!mounted) return;

    final bool hasValidData = _selectedDetection != null &&
        _categoryController.text.isNotEmpty;

    // Use addPostFrameCallback to ensure we're not in build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onFormDataChanged({
          // Basic form identification
          'formType': 'basic',
          'isFormComplete': _isFormAccepted && hasValidData,

          // Image data
          'imagePath': _image?.path,
          'images': _image != null ? [_image] : [],

          // AI Detection data
          'detections': _detections.map((d) => {
            'label': d.label,
            'confidence': d.confidence,
          }).toList(),

          'selectedDetection': _selectedDetection != null ? {
            'label': _selectedDetection!.label,
            'confidence': _selectedDetection!.confidence,
          } : null,

          // Form field data (matching main complaint form structure)
          'title': _categoryController.text.isNotEmpty ?
          '${_categoryController.text} - AI Detected Issue' : '',
          'description': _descriptionController.text,
          'category': _categoryController.text,
          'severity': _severityController.text,
          'department': _departmentController.text,
          'confidence': _confidenceController.text,

          // AI specific data
          'hasAiAnalysis': _selectedDetection != null,
          'aiAnalysis': _selectedDetection != null ?
          'AI detected ${_selectedDetection!.label} with ${_confidenceController.text} confidence' : '',
          'aiSuggestions': _selectedDetection != null ?
          _generateAISuggestions(_selectedDetection!.label) : '',

          // Status
          'hasValidDetection': _selectedDetection != null,
          'imageAnalyzed': _image != null && !_isAnalyzing,
          'formAccepted': _isFormAccepted,
        });
      }
    });
  }

  // Generate AI suggestions based on detection
  String _generateAISuggestions(String label) {
    switch (label.toLowerCase()) {
      case 'potholes':
        return 'Immediate road repair recommended for vehicle safety. Consider temporary marking until repairs can be completed.';
      case 'cracks':
        return 'Schedule preventive maintenance to prevent further deterioration. Monitor for expansion.';
      case 'open_manhole':
        return 'URGENT: Secure cover immediately for public safety. Deploy warning signs and barriers.';
      case 'animal':
        return 'Contact animal control services. Consider humane relocation if safe to do so.';
      case 'traffic light':
        return 'Report to traffic management for immediate inspection. Deploy temporary traffic control if needed.';
      case 'waste container':
        return 'Schedule waste collection and inspect container condition for replacement needs.';
      default:
        return 'Forward to appropriate department for assessment and action plan.';
    }
  }

  // Method to map AI labels to user-friendly categories
  String _mapLabelToCategory(String label) {
    switch (label.toLowerCase()) {
      case 'potholes':
        return 'Pothole';
      case 'cracks':
        return 'Road Crack';
      case 'open_manhole':
        return 'Open Manhole';
      case 'animal':
        return 'Stray Animal';
      case 'traffic light':
        return 'Traffic Signal Issue';
      case 'waste container':
        return 'Waste Management';
      default:
        return 'Other Issue';
    }
  }

  // Method to determine severity based on category
  String _mapCategoryToSeverity(String category) {
    switch (category) {
      case 'Pothole':
      case 'Open Manhole':
      case 'Traffic Signal Issue':
        return 'High';
      case 'Road Crack':
      case 'Stray Animal':
        return 'Medium';
      case 'Waste Management':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  // Method to assign appropriate department
  String _mapCategoryToDepartment(String category) {
    switch (category) {
      case 'Pothole':
      case 'Road Crack':
        return 'Roads & Infrastructure';
      case 'Open Manhole':
        return 'Water & Utilities';
      case 'Stray Animal':
        return 'Animal Control';
      case 'Traffic Signal Issue':
        return 'Traffic Management';
      case 'Waste Management':
        return 'Sanitation Department';
      default:
        return 'General Services';
    }
  }

  // Method to generate contextual description
  String _generateDescription(model.Detection detection) {
    String baseDescription = "AI detected ${detection.label} with ${(detection.confidence * 100).toStringAsFixed(1)}% confidence. ";

    switch (detection.label.toLowerCase()) {
      case 'potholes':
        return "${baseDescription}Road surface damage requiring immediate attention for vehicle safety.";
      case 'cracks':
        return "${baseDescription}Road surface deterioration that may worsen without maintenance.";
      case 'open_manhole':
        return "${baseDescription}Exposed utility access point posing safety hazard to pedestrians and vehicles.";
      case 'animal':
        return "${baseDescription}Stray animal spotted in the area requiring animal control intervention.";
      case 'traffic light':
        return "${baseDescription}Traffic signal malfunction or damage affecting traffic flow and safety.";
      case 'waste container':
        return "${baseDescription}Waste management issue requiring sanitation department attention.";
      default:
        return "${baseDescription}Issue detected requiring municipal attention.";
    }
  }

  // Method to get severity color
  Color _getSeverityColor() {
    switch (_severityController.text) {
      case 'High':
        return Colors.red.shade600;
      case 'Medium':
        return Colors.orange.shade600;
      case 'Low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Method to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return "Camera or storage permission denied. Please grant permissions in settings.";
    } else if (errorStr.contains('model') || errorStr.contains('onnx')) {
      return "AI model failed to load. Please check if model files are properly included.";
    } else if (errorStr.contains('decode') || errorStr.contains('image')) {
      return "Unable to process this image. Please try a different image format (JPG, PNG).";
    } else if (errorStr.contains('memory') || errorStr.contains('outofmemory')) {
      return "Image is too large to process. Please try a smaller image.";
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return "Network error. Please check your internet connection and try again.";
    } else {
      return "An unexpected error occurred during image analysis. Please try again.";
    }
  }

  // Method to show top notifications
  void _showTopNotification(String message, {bool isSuccess = false, bool isError = false, bool isWarning = false}) {
    if (!mounted) return;

    Widget notification;

    if (isError) {
      notification = CustomSnackBar.error(
        message: message,
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        backgroundColor: Colors.red.shade600,
        borderRadius: BorderRadius.circular(8),
        iconPositionTop: 12,
        iconRotationAngle: 0,
      );
    } else if (isWarning) {
      notification = CustomSnackBar.info(
        message: message,
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        backgroundColor: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(8),
        iconPositionTop: 12,
        iconRotationAngle: 0,
      );
    } else {
      notification = CustomSnackBar.success(
        message: message,
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        backgroundColor: Colors.green.shade600,
        borderRadius: BorderRadius.circular(8),
        iconPositionTop: 12,
        iconRotationAngle: 0,
      );
    }

    showTopSnackBar(
      Overlay.of(context),
      notification,
      animationDuration: const Duration(milliseconds: 800),
      reverseAnimationDuration: const Duration(milliseconds: 400),
      displayDuration: const Duration(seconds: 3),
    );
  }

  // Method to show quick toast messages
  void _showQuickToast(String message, {bool isSuccess = true}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // Main method to pick image and analyze
  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = null;
        _showNoDetectionWarning = false;
        _processingStep = "Preparing...";
        _isFormAccepted = false; // Reset acceptance when new image is analyzed
      });

      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      setState(() {
        _image = File(pickedFile.path);
        _detections.clear();
        _processingStep = "Loading image...";
      });

      // Show quick toast for start
      _showQuickToast("Starting AI analysis...", isSuccess: true);

      // Validate image file
      setState(() => _processingStep = "Validating image...");
      final imageBytes = await pickedFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw Exception("Selected image file is empty or corrupted");
      }

      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception("Unable to decode the selected image. Please try a different image.");
      }
      _decodedImage = decoded;

      // Run AI detection with progress updates
      setState(() => _processingStep = "Running AI models...");
      final results = await model.classifyWithMultipleModels(
        imageBytes,
        modelPaths,
        modelLabels,
        decoded,
      );

      setState(() => _processingStep = "Processing results...");

      // Small delay to show the final processing step
      await Future.delayed(const Duration(milliseconds: 300));

      // Handle detection results
      setState(() {
        _detections = results;
        _isAnalyzing = false;
        _processingStep = "";

        // Check if no detections were found
        if (results.isEmpty) {
          _showNoDetectionWarning = true;
        }
      });

      // Filter out low confidence detections
      final filteredResults = results.where((d) => d.confidence > 0.3).toList();

      if (filteredResults.isEmpty && results.isNotEmpty) {
        setState(() {
          _showNoDetectionWarning = true;
        });
      }

      // Auto-select highest confidence detection and prefill form
      if (filteredResults.isNotEmpty) {
        _selectedDetection = filteredResults.reduce((a, b) => a.confidence > b.confidence ? a : b);
        _prefillFormData(_selectedDetection!);
      } else {
        _clearFormData();
      }

      // Show success notification
      _showTopNotification(
        filteredResults.isNotEmpty
            ? "Found ${filteredResults.length} issue${filteredResults.length > 1 ? 's' : ''} in the image!"
            : "Image processed successfully, but no issues detected.",
        isSuccess: filteredResults.isNotEmpty,
        isWarning: filteredResults.isEmpty,
      );

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _processingStep = "";
        _errorMessage = _getErrorMessage(e);
      });

      _showTopNotification(_errorMessage!, isError: true);
    }
  }

  // Method to handle form acceptance
  void _handleAcceptForm() {
    if (_selectedDetection == null) return;

    setState(() {
      _isFormAccepted = true;
    });

    // Use addPostFrameCallback to ensure safe parent update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateFormData();
        _showTopNotification(
          "Form accepted! Proceed to select location and submit.",
          isSuccess: true,
        );
      }
    });
  }

  // Method to handle image upload with permission
  Future<void> _handleImageUpload() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _showSourcePicker();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      _showTopNotification("Camera permission is required.", isError: true);
    }
  }

  // Method to show source picker modal
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
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take a Photo'),
              subtitle: const Text('Use camera to capture'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Pick from existing photos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) await _pickAndAnalyzeImage(source);
  }

  // Widget to build loading indicator
  Widget _buildSmartLoadingIndicator() {
    if (!_isAnalyzing) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SpinKitThreeBounce(
                color: Colors.blue.shade600,
                size: 20.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _processingStep,
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            backgroundColor: Colors.blue.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ],
      ),
    );
  }

  // Widget to build detection results
  Widget _buildDetectionResults() {
    if (_detections.isEmpty && !_showNoDetectionWarning) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _detections.isNotEmpty ? Icons.check_circle : Icons.info_outline,
                    color: _detections.isNotEmpty ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _detections.isNotEmpty ? "Detection Results" : "No Issues Detected",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (_selectedDetection != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Selected: ${_selectedDetection!.label.toUpperCase()} (Highest confidence)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              if (_detections.isNotEmpty) ...[
                ...(_detections.map((detection) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          detection.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                          "${(detection.confidence * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList()),
              ] else if (_showNoDetectionWarning) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "The AI models couldn't detect any issues in this image.",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text("Possible reasons:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("• The image is clear of detectable issues", style: TextStyle(fontSize: 12)),
                      Text("• Image quality or lighting isn't optimal", style: TextStyle(fontSize: 12)),
                      Text("• The issue type isn't supported by our models", style: TextStyle(fontSize: 12)),
                      SizedBox(height: 8),
                      Text(
                        "💡 You can try a different image or switch to Advanced AI mode.",
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue.shade600, size: 28),
              const SizedBox(width: 8),
              Text(
                "Basic AI Mode",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _handleImageUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAnalyzing ? Colors.grey.shade400 : Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: _isAnalyzing ? 0 : 4,
              ),
              icon: _isAnalyzing
                  ? SpinKitThreeBounce(
                color: Colors.white,
                size: 16.0,
              )
                  : const Icon(Icons.add_a_photo, size: 24),
              label: Text(
                _isAnalyzing ? "Analyzing..." : "Upload Image for AI Detection",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          _buildSmartLoadingIndicator(),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Error",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showSourcePicker(),
                    child: Text(
                      "Retry",
                      style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_image != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      _image!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (_decodedImage != null && _detections.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DetectionPainter(
                            detections: _detections,
                            imageSize: Size(
                              _decodedImage!.width.toDouble(),
                              _decodedImage!.height.toDouble(),
                            ),
                          ),
                        ),
                      ),
                    if (_isAnalyzing)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SpinKitPulse(
                                color: Colors.white,
                                size: 60.0,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _processingStep,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _buildDetectionResults(),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                "Auto-Generated Report",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),

          if (_selectedDetection != null) ...[
            const SizedBox(height: 8),
            Text(
              "Form auto-populated based on highest confidence detection",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Category Field
          const Text("Category", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _categoryController,
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.grey.shade50,
              filled: true,
              prefixIcon: Icon(Icons.category, color: Colors.blue.shade600),
            ),
          ),

          const SizedBox(height: 16),

          // Confidence and Severity Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Confidence", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confidenceController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: Colors.green.shade50,
                        filled: true,
                        prefixIcon: Icon(Icons.verified, color: Colors.green.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Severity", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _severityController,
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: _getSeverityColor().withOpacity(0.1),
                        filled: true,
                        prefixIcon: Icon(Icons.priority_high, color: _getSeverityColor()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Department Field
          const Text("Department", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _departmentController,
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.purple.shade50,
              filled: true,
              prefixIcon: Icon(Icons.business, color: Colors.purple.shade600),
            ),
          ),

          const SizedBox(height: 16),

          // Description Field
          const Text("AI Generated Description", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(16),
              fillColor: Colors.amber.shade50,
              filled: true,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(Icons.description, color: Colors.amber.shade700),
              ),
            ),
          ),

          if (_selectedDetection == null && _image != null && !_isAnalyzing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No detections found. Try different lighting or switch to Advanced AI mode for manual reporting.",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Accept Form Button (replacing Submit button)
          if (_selectedDetection != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: !_isFormAccepted ? _handleAcceptForm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormAccepted
                      ? Colors.green.shade600
                      : Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: Icon(
                  _isFormAccepted ? Icons.check_circle : Icons.arrow_forward,
                  size: 20,
                ),
                label: Text(
                  _isFormAccepted ? "Form Accepted ✓" : "Accept & Continue",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // Form acceptance status
          if (_isFormAccepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Form data ready! Now proceed to select location and submit your complaint.",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<model.Detection> detections;
  final Size imageSize;

  DetectionPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (final det in detections) {
      final left = (det.x - det.w / 2) * scaleX;
      final top = (det.y - det.h / 2) * scaleY;
      final width = det.w * scaleX;
      final height = det.h * scaleY;

      final rect = Rect.fromLTWH(left, top, width, height);

      // Draw filled rectangle
      canvas.drawRect(rect, fillPaint);
      // Draw border
      canvas.drawRect(rect, paint);

      // Draw label with background
      final label = "${det.label} ${(det.confidence * 100).toStringAsFixed(1)}%";
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Draw background for text
      final textBackground = Paint()..color = Colors.red;
      canvas.drawRect(
        Rect.fromLTWH(left, top - 20, textPainter.width + 8, 20),
        textBackground,
      );

      textPainter.paint(canvas, Offset(left + 4, top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}