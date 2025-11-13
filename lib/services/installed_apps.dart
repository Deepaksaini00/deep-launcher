import 'package:permission_handler/permission_handler.dart';
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
      for (var app in installedApps) {
        print('→ ${app.name} (${app.packageName})');
      }

      print('✅ Total user apps found: ${installedApps.length}');
      return installedApps;
    } catch (e) {
      print('⚠️ Error fetching apps: $e');
      return [];
    }
  }

  // Add App to Pinned Apps List..!!
  static Future<void> addToPinned(AppInfo app) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];

    // Avoid duplicates
    if (!pinnedApps.any((a) => jsonDecode(a)['package'] == app.packageName)) {
      pinnedApps.add(
        jsonEncode({'name': app.name, 'package': app.packageName}),
      );
      await prefs.setStringList(_pinnedKey, pinnedApps);
      print('📌 Pinned app: ${app.name}');
    }
  }

  // Remove App from Pinned Apps List..!!
  static Future<void> removePinned(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];
    pinnedApps.removeWhere((a) => jsonDecode(a)['package'] == packageName);
    await prefs.setStringList(_pinnedKey, pinnedApps);
  }

  // Get all Pinned Apps...!!
  static Future<List<AppInfo>> getPinnedApps() async {
    List<AppInfo> pinnedAppList = [];
    final prefs = await SharedPreferences.getInstance();
    List<String> pinnedApps = prefs.getStringList(_pinnedKey) ?? [];

    for (var item in pinnedApps) {
      var data = jsonDecode(item);
      try {
        var app = await InstalledApps.getAppInfo(data['package']);
        if (app != null) {
          pinnedAppList.add(app);
        }
      } catch (_) {}
    }
    return pinnedAppList;
  }
}
