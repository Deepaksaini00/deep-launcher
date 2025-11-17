import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InstalledAppsService {
  // List of pinned Apps..

  static const _pinnedKey = 'pinned_apps';

  // Fetch and print Installed apps...

  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      // List of Installed apps..
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      print('📱 Installed user apps:');
      // for (var app in installedApps) {
      //   print('→ ${app.name} (${app.packageName})');
      // }

      print('✅ Total user apps found: ${installedApps.length}');
      return installedApps;
    } catch (e) {
      print('⚠️ Error fetching apps: $e');
      return [];
    }
  }

  // =====
  // Add App to Pinned Apps List..!!
  // ====

  static Future<void> addToPinned(AppInfo app) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    final jsonItem = {
      "packageName": app.packageName,
      "name": app.name,
      "iconSlug": null,
    };

    // Avoid duplicates
    if (!pinnedApps.any(
      (a) => jsonDecode(a)['packageName'] == app.packageName,
    )) {
      pinnedApps.add(jsonEncode(jsonItem));
      await prefs.setStringList(_pinnedKey, pinnedApps);
      print('📌 Pinned app: ${app.name}');
    }
  }

  // Remove App from Pinned Apps List..!!
  static Future<void> removePinned(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    pinnedApps.removeWhere((a) => jsonDecode(a)['packageName'] == packageName);
    await prefs.setStringList(_pinnedKey, pinnedApps);
    print("🗑 Removed $packageName");
  }

  // Get all Pinned Apps...!!
  static Future<List<AppInfo>> getPinnedApps() async {
    List<AppInfo> pinnedAppList = [];
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];

    for (var item in pinnedApps) {
      try {
        final data = jsonDecode(item);
        if (data['packageName'] == null) {
          print("~~ ❌ Invalid entry (missing packageName): $data");
          continue;
        }

        final app = await InstalledApps.getAppInfo(data["packageName"]);
        if (app != null) {
          pinnedAppList.add(app);
        }
      } catch (e) {
        print(">>> ❌ JSON error: $e → $item");
      }
    }
    return pinnedAppList;
  }

  // ✅ Save custom icon key
  static Future<void> saveIcons(String packageName, String iconKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(packageName, iconKey);
  }

  // Load icons
  static Future<String?> getSavedIcon(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(packageName);
  }

  // Pinned Apps Export Json
  static Future<String?> exportPinnedApps() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    if (pinnedApps.isEmpty) return null;
    final jsonString = jsonEncode(pinnedApps);
    return jsonEncode(pinnedApps);
  }

  // === IMPORT PINNED APPS ===
  static Future<void> importPinnedApps(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoded = jsonDecode(jsonString);
      List<String> cleanList = decoded.map<String>((e) {
        final obj = jsonDecode(e);

        return jsonEncode({
          "packageName": obj["packageName"],
          "name": obj["name"] ?? "",
          "iconSlug": obj["iconSlug"],
        });
      }).toList();

      await prefs.setStringList(_pinnedKey, cleanList);
      print("📥 Imported ${cleanList.length} pinned apps");

      // List<String> pinnedList = decoded
      //     .map<String>((e) => jsonEncode(jsonDecode(e)))
      //     .toList();

      // // List<String> pinnedList = jsonEncode(jsonDecode(e).map((e) => e.toString()).toList();
      // await prefs.setStringList(_pinnedKey, pinnedList);
    } catch (e) {
      print("<<<< Error Importing pinned apps: $e");
    }
  }

  static Future<void> printPinnedAppsPretty() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned = prefs.getStringList(_pinnedKey) ?? [];

    print("🟢 PINNED APPS (Parsed):");

    for (var item in pinned) {
      try {
        final data = jsonDecode(item);
        print("Package: ${data['packageName']}, Icon: ${data['iconSlug']}");
      } catch (e) {
        print("--- Invalid JSON: $item");
      }
    }
  }
}
