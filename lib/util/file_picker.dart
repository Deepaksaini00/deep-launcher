import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class GridAppPicker {
  static const _exportFileName = "deep_launcher.json";
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

  static Future<String?> saveJsonFile(String json) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save grid apps',
      fileName: _exportFileName,
      type: FileType.any,
      bytes: utf8.encode(json),
    );

    if (path == null) {
      debugPrint("📤 Export canceled by user");
      return null;
    }

    debugPrint("📤 Exported JSON saved at: $path");

    return path;
  }
}
