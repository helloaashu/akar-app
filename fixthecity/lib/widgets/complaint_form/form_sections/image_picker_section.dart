import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerSection extends StatelessWidget {
  final List<XFile>? selectedImages;
  final Function(ImageSource) onPickImage;
  final Function(int) onRemoveImage;
  final ImagePicker picker;

  const ImagePickerSection({
    Key? key,
    required this.selectedImages,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.picker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          label: const Text(
            'Choose File',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 17),
        if (selectedImages != null && selectedImages!.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: selectedImages!.length,
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                children: [
                  Image.file(
                    File(selectedImages![index].path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onRemoveImage(index),
                      child: Container(
                        color: Colors.redAccent,
                        child: const Icon(
                          Icons.cancel,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
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
                onPickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }
}