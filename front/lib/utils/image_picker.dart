import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from the specified source (gallery or camera)
  static Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      } else {
        debugPrint('No image selected.');
        return null;
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}