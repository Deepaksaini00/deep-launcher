import 'package:file_picker/file_picker.dart';
import 'dart:io';

class GridAppPicker {
  static Future<String?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['json'],
      type: FileType.custom,
    );
    if (result == null) return null;
    final filePath = result.files.single.path!;
    final file = File(filePath);
    return await file.readAsString();
  }
}
