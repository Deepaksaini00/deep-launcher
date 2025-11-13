// import 'package:permission_handler/permission_handler.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class InstalledAppsService {
  // List of pinned Apps..
  static List<AppInfo> pinnedApps = [];

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
  static void addToPinned(AppInfo app) {
    if (!pinnedApps.any((a) => a.packageName == app.packageName)) {
      pinnedApps.add(app);
    }
  }

  // Remove App from Pinned Apps List..!!
  static void removePinned(AppInfo app) {
    pinnedApps.removeWhere((a) => a.packageName == app.packageName);
  }

  // Get all Pinned Apps...!!
  static List<AppInfo> getPinnedApps() {
    return pinnedApps;
  }
}
