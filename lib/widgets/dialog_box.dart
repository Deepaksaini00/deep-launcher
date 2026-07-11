import 'package:android_launcher/icons/app_icons.dart';
import 'package:android_launcher/services/installed_apps.dart';
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
          title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.app_settings_alt_outlined),
                title: Text(
                  "Open App Setting",
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
                leading: Icon(app.isSystemApp ? Icons.info_outline : Icons.delete_forever),
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
        title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              leading: Icon(app.isSystemApp ? Icons.info_outline : Icons.delete_forever),
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
  ) {
    TextEditingController searchIconCtrl = TextEditingController();
    List<MapEntry<String, IconData>> filteredIcons = icons.entries.toList();
    void updateSearch(String query) {
      filteredIcons = icons.entries
          .where((e) => e.key.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TITLE
                      const Text(
                        "Pick an icon",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // SEARCH BOX
                      TextField(
                        controller: searchIconCtrl,
                        onChanged: (value) {
                          setState(() => updateSearch(value));
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: "Search",
                          filled: true,
                          fillColor: const Color.fromARGB(255, 212, 211, 211),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ICON GRID
                      SizedBox(
                        height: 260,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredIcons.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemBuilder: (context, index) {
                            final entry = filteredIcons[index];

                            return GestureDetector(
                              onTap: () {
                                InstalledAppsService.saveIcons(
                                  app.packageName,
                                  entry.key,
                                );
                                Navigator.pop(context);
                                refresh();
                              },
                              child: Icon(
                                entry.value,
                                size: 30,
                                // color: const Color.fromARGB(221, 0, 0, 0),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      // CLOSE BUTTON
                      TextButton(
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            color: Color.fromARGB(255, 181, 18, 0),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
