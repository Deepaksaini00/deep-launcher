import 'package:flutter/widgets.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InstalledAppsService {
  // List of pinned Apps..

  static const _pinnedKey = 'pinned_apps';
  static List<AppInfo>? _installedCache;
  static List<AppInfo> _cachedPinnedApps = [];
  static Map<String, String?> _cachedIcons = {};
  // Fetch and print Installed apps...

  static Future<List<AppInfo>> getInstalledApps() async {
    if (_installedCache != null) return _installedCache!;
    try {
      // List of Installed apps..
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      print('📱 Installed user apps:');
      print('✅ Total user apps found: ${installedApps.length}');
      _installedCache = installedApps;
      return installedApps;
    } catch (e) {
      print('⚠️ Error fetching apps: $e');
      return [];
    }
  }

  static Future<void> refreshInstalledApps() async {
    _installedCache = null; // Clear cache
    _cachedPinnedApps = []; // Clear pinned cache
    await getInstalledApps(); // Reload fresh data
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
      if (!_cachedPinnedApps.any((a) => a.packageName == app.packageName)) {
        _cachedPinnedApps.add(app);
      }
      // _cachedPinnedApps.add(app);
      print('📌 Pinned app: ${app.name}');
    }
  }

  // Remove App from Pinned Apps List..!!
  static Future<void> removePinned(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    pinnedApps.removeWhere((a) => jsonDecode(a)['packageName'] == packageName);
    await prefs.setStringList(_pinnedKey, pinnedApps);
    _cachedPinnedApps.removeWhere((a) => a.packageName == packageName);
    print("🗑 Removed $packageName");
  }

  // Get all Pinned Apps...!!
  static Future<List<AppInfo>> getPinnedApps() async {
    if (_cachedPinnedApps.isNotEmpty) {
      return _cachedPinnedApps;
    }
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
    _cachedPinnedApps = pinnedAppList;
    return pinnedAppList;
  }

  // ✅ Save custom icon key
  static Future<void> saveIcons(String packageName, String iconKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(packageName, iconKey);
    _cachedIcons[packageName] = iconKey;
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    bool changed = false;
    for (int i = 0; i < pinnedApps.length; i++) {
      try {
        final map = jsonDecode(pinnedApps[i]) as Map<String, dynamic>;
        if (map['packageName'] == packageName) {
          map['iconSlug'] = iconKey;
          pinnedApps[i] = jsonEncode(map);
          changed = true;
          break;
        }
      } catch (e) {
        // ignore invalid entries
      }
    }
    if (changed) {
      await prefs.setStringList(_pinnedKey, pinnedApps);
    }
  }

  // Load icons
  static Future<String?> getSavedIcon(String packageName) async {
    if (_cachedIcons.containsKey(packageName)) {
      return _cachedIcons[packageName];
    }
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(packageName);
    _cachedIcons[packageName] = key;
    return key;
    // return prefs.getString(packageName);
  }

  static String? getSavedIconSync(String packageName) {
    return _cachedIcons[packageName];
  }

  // Pinned Apps Export Json
  static Future<String?> exportPinnedApps() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    if (pinnedApps.isEmpty) return null;
    List<Map<String, dynamic>> data = pinnedApps
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    // final jsonString = jsonEncode(pinnedApps);
    return jsonEncode(data);
  }

  // === IMPORT PINNED APPS ===
  static Future<void> importPinnedApps(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final decoded = jsonDecode(jsonString);
      // decoded must be a List of objects
      if (decoded is! List) {
        print("❌ Imported JSON is not a list");
        return;
      }
      List<String> newList = decoded.map<String>((map) {
        // final obj = jsonDecode(e);

        return jsonEncode({
          "packageName": map["packageName"],
          "name": map["name"] ?? "",
          "iconSlug": map["iconSlug"],
        });
      }).toList();

      await prefs.setStringList(_pinnedKey, newList);
      print("📥 Imported ${newList.length} pinned apps");
      _cachedPinnedApps = [];
      _cachedIcons.clear();
      for (var item in newList) {
        try {
          final data = jsonDecode(item);
          final packageName = data['packageName'];
          final iconSlug = await prefs.getString(packageName);
          if (iconSlug != null) {
            _cachedIcons[packageName] = iconSlug;
          } else if (data['iconSlug'] != null) {
            // Save the iconSlug into SharedPreferences for consistency
            await prefs.setString(packageName, data['iconSlug']);
            _cachedIcons[packageName] = data['iconSlug'];
          }
        } catch (e) {
          //ignore errors....
        }
      }
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
