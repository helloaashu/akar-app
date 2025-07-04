import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/road_issue_analysis.dart';
import '../../services/ai_services.dart';
import 'ai_analysis_section.dart';

class AiImagePickerSection extends StatefulWidget {
  final List<XFile>? selectedImages;
  final Function(XFile) onImageAdded;
  final Function(int) onRemoveImage;
  final Function(RoadIssueAnalysis) onAnalysisComplete;
  final ImagePicker picker;

  const AiImagePickerSection({
    Key? key,
    required this.selectedImages,
    required this.onImageAdded,
    required this.onRemoveImage,
    required this.onAnalysisComplete,
    required this.picker,
  }) : super(key: key);

  @override
  State<AiImagePickerSection> createState() => _AiImagePickerSectionState();
}

class _AiImagePickerSectionState extends State<AiImagePickerSection> {
  RoadIssueAnalysis? _analysis;
  bool _isAnalyzing = false;
  bool _hasUserDecided = false;

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final XFile? photo = await widget.picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return;

      // Check if we can add more images
      if (widget.selectedImages != null && widget.selectedImages!.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only select up to 3 images in total.'),
          ),
        );
        return;
      }

      // Add image to the list
      widget.onImageAdded(photo);

      // If this is the first image, analyze it
      if (widget.selectedImages!.length == 1 && !_hasUserDecided) {
        await _analyzeImage(File(photo.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
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
      // Silently fail - user can still fill form manually
      print('AI Analysis failed: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _acceptAiSuggestions() {
    if (_analysis != null && _analysis!.isRelevant) {
      widget.onAnalysisComplete(_analysis!);
      setState(() {
        _hasUserDecided = true;
      });
    }
  }

  void _rejectAiSuggestions() {
    setState(() {
      _hasUserDecided = true;
      _analysis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Analysis Section (shows only after first image)
        if ((widget.selectedImages?.isNotEmpty ?? false) && !_hasUserDecided)
          AiAnalysisSection(
            analysis: _analysis,
            isAnalyzing: _isAnalyzing,
            onAcceptSuggestions: _acceptAiSuggestions,
            onRejectSuggestions: _rejectAiSuggestions,
          ),

        if ((widget.selectedImages?.isNotEmpty ?? false) && !_hasUserDecided)
          const SizedBox(height: 20),

        // Image picker button
        ElevatedButton.icon(
          onPressed: () => _showImageSourceDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue.shade800,
            minimumSize: const Size(160, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: const Icon(Icons.photo, color: Colors.white),
          label: Text(
            widget.selectedImages?.isEmpty ?? true
                ? 'Add Photo (AI will analyze)'
                : 'Add More Photos',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Selected images grid
        if (widget.selectedImages != null && widget.selectedImages!.isNotEmpty) ...[
          const SizedBox(height: 17),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: widget.selectedImages!.length,
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(widget.selectedImages![index].path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => widget.onRemoveImage(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (index == 0 && _analysis != null && _analysis!.isRelevant)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndAnalyzeImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndAnalyzeImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }
}