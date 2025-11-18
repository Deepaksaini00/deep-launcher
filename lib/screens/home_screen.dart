import 'package:android_launcher/icons/app_icons.dart';
import 'package:android_launcher/services/global_actions.dart';
import 'package:android_launcher/services/installed_apps.dart';
import 'package:android_launcher/util/file_picker.dart';
import 'package:android_launcher/widgets/dialog_box.dart';
import 'package:android_launcher/widgets/theme_picker.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSearching = false;
  // Store Icons for 12 apps...
  List<IconData?> homeIcons = List.filled(12, null);
  IconData defaultIcon = Icons.apps;

  // Search Controller..
  TextEditingController searchController = TextEditingController();

  // Store installed apps ..
  List<AppInfo> installedApps = [];
  List<AppInfo> filteredApps = [];
  List<AppInfo> pinnedApps = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
    InstalledAppsService.printPinnedAppsPretty();
  }

  void _loadApps() async {
    var apps = await InstalledAppsService.getInstalledApps();
    var pinned = await InstalledAppsService.getPinnedApps();
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // final prefs = await SharedPreferences.getInstance();
    // prefs.remove('pinned_apps');
    // print("🗑️ Cleared old broken pinned apps");
    setState(() {
      installedApps = apps;
      filteredApps = apps;
      pinnedApps = pinned;
    });
  }

  Widget buildTile(AppInfo app) {
    return FutureBuilder<String?>(
      future: InstalledAppsService.getSavedIcon(app.packageName),
      builder: (context, snapshot) {
        String? iconKey = snapshot.data;
        IconData iconToShow = icons[iconKey] ?? defaultIcon;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async => await InstalledApps.startApp(app.packageName),

          onLongPress: () {
            AppDialogs.pinnedDialogBox(context, app, _loadApps);
          },

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(iconToShow, size: 45), const SizedBox(height: 6)],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: -2,
        backgroundColor: const Color.fromARGB(
          255,
          124,
          123,
          123,
          // ignore: deprecated_member_use
        ).withOpacity(0.45),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1️⃣ GridView (center of screen) >>>>
              Expanded(
                child: Center(
                  child: GridView.count(
                    crossAxisCount: 2,
                    primary: false,
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      // bottom: 10,
                      top: 30,
                    ),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    physics: NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: List.generate(pinnedApps.length, (index) {
                      final app = pinnedApps[index];
                      return buildTile(app);
                    }),
                  ),
                ),
              ),

              // 2️⃣ Search bar + 3-dot button (bottom) >>>>>
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 5.0,
                  left: 8.0,
                  right: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            210,
                            204,
                            204,

                            // ignore: deprecated_member_use
                          ).withOpacity(0.45), // Dark gray background
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: false,
                          focusNode: FocusNode(skipTraversal: true),
                          onTap: () {
                            if (!isSearching) {
                              setState(() => isSearching = true);
                            }
                          },
                          // Filter the apps ...
                          onChanged: (query) {
                            setState(() {
                              filteredApps = installedApps
                                  .where(
                                    (app) => app.name.toLowerCase().contains(
                                      query.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                            });
                          },

                          decoration: InputDecoration(
                            prefixIcon: isSearching
                                ? GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        isSearching = false;
                                        searchController.clear();
                                      });
                                    },
                                    child: const SizedBox(
                                      width:
                                          40, // fixed width so search box size doesn't change
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_back,
                                          color: Colors.black,
                                          size: 28, // adjust as needed
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 40),

                            hintText: 'Search Apps ${installedApps.length}',
                            hintStyle: TextStyle(
                              color: const Color.fromARGB(230, 28, 28, 28),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Color.fromARGB(253, 0, 0, 0),
                              ),
                              onPressed: () async {
                                // 3- dot working do it later....
                                final action = await askGlobalAction(context);
                                switch (action) {
                                  case GlobalAction.refreshApps:
                                    _loadApps();
                                    break;
                                  case GlobalAction.exportGridJson:
                                    final String? json =
                                        await InstalledAppsService.exportPinnedApps();
                                    if (json != null) {
                                      await GridAppPicker.saveFileToLocalStorage(
                                        json,
                                      );
                                    }
                                    break;
                                  case GlobalAction.importGridJson:
                                    final jsonFile =
                                        await GridAppPicker.pickJsonFile();
                                    if (jsonFile != null) {
                                      await InstalledAppsService.importPinnedApps(
                                        jsonFile,
                                      );
                                      _loadApps();
                                    }

                                    break;
                                  case GlobalAction.changeTheme:
                                    await showThemePickerDialog(context);
                                    break;
                                  default:
                                    break;
                                }
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isSearching)
            Positioned(
              top: 60,
              left: 10,
              right: 0,
              bottom: 80,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 30),
                  itemCount: filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    return ListTile(
                      title: Text(
                        app.name,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      onTap: () async {
                        await InstalledApps.startApp(app.packageName);
                      },
                      onLongPress: () {
                        AppDialogs.appDialogBox(context, app, _loadApps);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
