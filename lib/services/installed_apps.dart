import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class InstalledAppsService {
  // List of pinned Apps..

  static const _pinnedKey = 'pinned_apps';
  static const _installedAppsKey = 'installed_apps_cache';
  static List<AppInfo>? _installedCache;
  static List<AppInfo> _cachedPinnedApps = [];
  static final Map<String, String?> _cachedIcons = {};

  // Save installed apps list to SharedPreferences cache
  static Future<void> _saveInstalledAppsToPrefs(List<AppInfo> apps) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> list = apps.map((app) {
        return jsonEncode({
          "name": app.name,
          "package_name": app.packageName,
          "version_name": app.versionName,
          "version_code": app.versionCode,
          "platform_type": app.platformType.slug,
          "installed_timestamp": app.installedTimestamp,
          "is_system_app": app.isSystemApp,
          "is_launchable_app": app.isLaunchableApp,
        });
      }).toList();
      await prefs.setStringList(_installedAppsKey, list);
    } catch (e) {
      debugPrint("⚠️ Error saving installed apps cache: $e");
    }
  }

  // Load installed apps list from SharedPreferences cache
  static Future<List<AppInfo>> _loadInstalledAppsFromPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? list = prefs.getStringList(_installedAppsKey);
      if (list == null || list.isEmpty) return [];
      return list.map((item) {
        final Map<String, dynamic> data = jsonDecode(item);
        return AppInfo.create(data);
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error loading installed apps cache: $e");
      return [];
    }
  }

  // Fetch and print Installed apps...
  static Future<List<AppInfo>> getInstalledApps() async {
    if (_installedCache != null) return _installedCache!;
    
    // Try to load from persistent cache first
    final cached = await _loadInstalledAppsFromPrefs();
    if (cached.isNotEmpty) {
      _installedCache = cached;
      return cached;
    }

    try {
      // List of Installed apps..
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      debugPrint('📱 Installed user apps loaded from system (first run):');
      debugPrint('✅ Total user apps found: ${installedApps.length}');
      _installedCache = installedApps;
      await _saveInstalledAppsToPrefs(installedApps);
      return installedApps;
    } catch (e) {
      debugPrint('⚠️ Error fetching apps: $e');
      return [];
    }
  }

  static Future<void> refreshInstalledApps() async {
    _installedCache = null; // Clear cache
    _cachedPinnedApps = []; // Clear pinned cache
    try {
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      debugPrint('📱 Refreshed installed user apps from system');
      _installedCache = installedApps;
      await _saveInstalledAppsToPrefs(installedApps);
    } catch (e) {
      debugPrint('⚠️ Error refreshing apps: $e');
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
      if (!_cachedPinnedApps.any((a) => a.packageName == app.packageName)) {
        _cachedPinnedApps.add(app);
      }
      // _cachedPinnedApps.add(app);
      debugPrint('📌 Pinned app: ${app.name}');
    }
  }

  // Remove App from Pinned Apps List..!!
  static Future<void> removePinned(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    pinnedApps.removeWhere((a) => jsonDecode(a)['packageName'] == packageName);
    await prefs.setStringList(_pinnedKey, pinnedApps);
    _cachedPinnedApps.removeWhere((a) => a.packageName == packageName);
    debugPrint("🗑 Removed $packageName");
  }

  // Update pinned apps order
  static Future<void> updatePinnedAppsOrder(List<AppInfo> apps) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> currentPinned = prefs.getStringList(_pinnedKey) ?? [];
    List<String> newPinnedList = [];
    
    for (var app in apps) {
      String? found;
      for (var jsonStr in currentPinned) {
        try {
          final data = jsonDecode(jsonStr);
          if (data['packageName'] == app.packageName) {
            found = jsonStr;
            break;
          }
        } catch (_) {}
      }
      if (found != null) {
        newPinnedList.add(found);
      } else {
        newPinnedList.add(jsonEncode({
          "packageName": app.packageName,
          "name": app.name,
          "iconSlug": null,
        }));
      }
    }
    await prefs.setStringList(_pinnedKey, newPinnedList);
    _cachedPinnedApps = List.from(apps);
  }

  // Get all Pinned Apps...!!
  static Future<List<AppInfo>> getPinnedApps() async {
    if (_cachedPinnedApps.isNotEmpty) {
      return _cachedPinnedApps;
    }
    List<AppInfo> pinnedAppList = [];
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    List<String> validPinnedApps = [];

    final allApps = await getInstalledApps();

    for (var item in pinnedApps) {
      try {
        final data = jsonDecode(item);
        final packageName = data['packageName'];
        if (packageName == null) {
          continue;
        }

        final int index = allApps.indexWhere((a) => a.packageName == packageName);
        if (index != -1) {
          pinnedAppList.add(allApps[index]);
          validPinnedApps.add(item);
        } else {
          try {
            final app = await InstalledApps.getAppInfo(packageName);
            if (app != null) {
              pinnedAppList.add(app);
              validPinnedApps.add(item);
            }
          } catch (_) {
            // App is not installed, prune it from pinned list
          }
        }
      } catch (e) {
        debugPrint(">>> ❌ JSON error: $e → $item");
      }
    }
    if (validPinnedApps.length != pinnedApps.length) {
      await prefs.setStringList(_pinnedKey, validPinnedApps);
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
        debugPrint("❌ Imported JSON is not a list");
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
      debugPrint("📥 Imported ${newList.length} pinned apps");
      _cachedPinnedApps = [];
      _cachedIcons.clear();
      for (var item in newList) {
        try {
          final data = jsonDecode(item);
          final packageName = data['packageName'];
          final iconSlug = prefs.getString(packageName);
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
      debugPrint("<<<< Error Importing pinned apps: $e");
    }
  }

  static Future<void> printPinnedAppsPretty() async {
    final prefs = await SharedPreferences.getInstance();
    final pinned = prefs.getStringList(_pinnedKey) ?? [];

    debugPrint("🟢 PINNED APPS (Parsed):");

    for (var item in pinned) {
      try {
        final data = jsonDecode(item);
        debugPrint("Package: ${data['packageName']}, Icon: ${data['iconSlug']}");
      } catch (e) {
        debugPrint("--- Invalid JSON: $item");
      }
    }
  }
}
