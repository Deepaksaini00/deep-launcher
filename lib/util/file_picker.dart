import 'package:file_picker/file_picker.dart';
import 'dart:io';

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

  static Future<String> saveFileToLocalStorage(String json) async {
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
