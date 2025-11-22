import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

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

  static Future<void> requestAllFilesAccess() async {
    if (await Permission.manageExternalStorage.isGranted) return;

    final status = await Permission.manageExternalStorage.request();

    if (!status.isGranted) {
      await openAppSettings();
      throw Exception("User denied MANAGE_EXTERNAL_STORAGE");
    }
  }

  static Future<String> saveFileToLocalStorage(String json) async {
    await requestAllFilesAccess(); // <-- ADD THIS LINE
    final downloadsDir = Directory("/storage/emulated/0/Download");

    if (!downloadsDir.existsSync()) {
      throw Exception("⚠️ Download folder not found!");
    }

    final file = File("${downloadsDir.path}/$_exportFileName");

    // Write bytes (required on Android)
    await file.writeAsBytes(json.codeUnits, flush: true);

    print("📤 Exported JSON saved at: ${file.path}");

    return file.path;
  }
}
