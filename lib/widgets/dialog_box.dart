import 'package:android_launcher/services/installed_apps.dart';
import 'package:android_launcher/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppDialogs {
  // 1️⃣ App Drawer Dialog
  // 1️⃣ App Drawer Dialog
  static void appDialogBox(
    BuildContext context,
    AppInfo app,
    VoidCallback refresh,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            app.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  "App Info",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                onTap: () async {
                  InstalledApps.openSettings(app.packageName);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_to_home_screen),
                title: Text(
                  "Add to Home",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await InstalledAppsService.addToPinned(app);
                  navigator.pop();
                  refresh();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: Text(
                  "Uninstall App",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (app.isSystemApp) {
                    InstalledApps.openSettings(app.packageName);
                  } else {
                    await InstalledApps.uninstallApp(app.packageName);
                  }
                  refresh();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 2️⃣ Home Screen Dialog
  static void pinnedDialogBox(
    BuildContext context,
    AppInfo app,
    VoidCallback refresh,
    void Function(String) removeFromPinnedCache,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(
          app.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(
                "Remove From Home",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                await InstalledAppsService.removePinned(app.packageName);
                removeFromPinnedCache(app.packageName);
                navigator.pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(
                "Select Icon",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                AppDialogs.iconDialogBox(context, app, refresh);
              },
            ),
            ListTile(
              leading: Icon(
                app.isSystemApp ? Icons.info_outline : Icons.delete_forever,
              ),
              title: Text(
                app.isSystemApp ? "App Info" : "Delete App",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (app.isSystemApp) {
                  InstalledApps.openSettings(app.packageName);
                } else {
                  await InstalledApps.uninstallApp(app.packageName);
                }
                refresh();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3️⃣ Icon Picker Dialog
  static void iconDialogBox(
    BuildContext context,
    AppInfo app,
    VoidCallback refresh,
  ) async {
    final picked = await showIconPicker(context);
    if (picked == null || !context.mounted) return;
    if (picked == kUseOriginalIcon) {
      await InstalledAppsService.removeSavedIcon(app.packageName);
    } else {
      await InstalledAppsService.saveIcons(app.packageName, picked);
    }
    refresh();
  }
}
