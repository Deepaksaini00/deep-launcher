import 'package:android_launcher/icons/app_icons.dart';
import 'package:android_launcher/services/installed_apps.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppDialogs {
  // 1️⃣ App Drawer Dialog
  static void appDialogBox(BuildContext context, AppInfo app, refresh) {
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
                onTap: () async {
                  await InstalledAppsService.addToPinned(app);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  refresh();
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

  // 2️⃣ Home Screen Dialog
  static void pinnedDialogBox(
    BuildContext context,
    AppInfo app,
    VoidCallback refresh,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(
          0xFFCFCFCF,
        ), //  const Color.fromARGB(255, 106, 135, 149),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Text(app.name, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Remove From Home"),
              onTap: () {
                InstalledAppsService.removePinned(app.packageName);
                Navigator.pop(context);
                refresh();
              },
            ),
            // const Divider(),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Select Icon"),
              onTap: () async {
                Navigator.pop(context);
                AppDialogs.iconDialogBox(context, app, refresh);
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
                          fillColor: Colors.grey.shade200,
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
                                color: const Color.fromARGB(221, 0, 0, 0),
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
                            color: Color.fromARGB(255, 23, 145, 246),
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
