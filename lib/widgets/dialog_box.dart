import 'package:android_launcher/services/installed_apps.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

Future<void> dialogBox(BuildContext context, AppInfo app) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color.fromARGB(255, 106, 135, 149),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(app.name, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text("Add To Main Grid"),
              onTap: () {
                InstalledAppsService.addToPinned(app);
                Navigator.pop(context);
              },
            ),
            // const Divider(),
            ListTile(
              leading: const Icon(Icons.app_settings_alt_outlined),
              title: const Text("Open App Setting"),
              onTap: () async {
                InstalledApps.openSettings(app.packageName);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
