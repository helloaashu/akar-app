import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageUtils {
  static Future<File?> compressImage(File file) async {
    final String targetPath =
        "${file.parent.path}/compressed_${file.uri.pathSegments.last}";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    return result;
  }

  static Future<List<String>> uploadImages(
      List<XFile> images, String complaintId) async {
    List<String> downloadUrls = [];

    for (var image in images) {
      File originalFile = File(image.path);
      File? compressedFile = await compressImage(originalFile);
      final fileToUpload = compressedFile ?? originalFile;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('complaints/$complaintId/${image.name}');
      final uploadTask = await storageRef.putFile(fileToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  static Future<PermissionStatus> requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.camera,
    ].request();

    if (statuses[Permission.storage]!.isGranted &&
        statuses[Permission.camera]!.isGranted) {
      return PermissionStatus.granted;
    }
    return PermissionStatus.denied;
  }
}