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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  Map<String, String?> iconKeyCache = {};
  bool isSearching = false;
  bool isAppScreenVisible = false;
  // Store Icons for 12 apps...
  List<IconData?> homeIcons = List.filled(12, null);
  IconData defaultIcon = Icons.apps;

  // Search Controller..
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  // Store installed apps ..
  List<AppInfo> installedApps = [];
  List<AppInfo> filteredApps = [];
  List<AppInfo> pinnedApps = [];
  List<AppInfo> _displayPinnedApps = [];

  void removeFromPinnedCache(String packageName) {
    setState(() {
      pinnedApps.removeWhere((a) => a.packageName == packageName);
      _displayPinnedApps.removeWhere((a) => a.packageName == packageName);
      iconKeyCache.remove(packageName);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadApps();
    InstalledAppsService.printPinnedAppsPretty();
  }

  void _loadApps({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await InstalledAppsService.refreshInstalledApps();
    }
    var apps = await InstalledAppsService.getInstalledApps();
    var pinned = await InstalledAppsService.getPinnedApps();
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // final prefs = await SharedPreferences.getInstance();
    // prefs.remove('pinned_apps');
    // print("🗑️ Cleared old broken pinned apps");
    for (final app in pinned) {
      await InstalledAppsService.getSavedIcon(app.packageName);
    }
    setState(() {
      installedApps = apps;
      filteredApps = apps;
      pinnedApps = pinned;

      if (_displayPinnedApps.length != pinned.length ||
          !_listMatch(_displayPinnedApps, pinned)) {
        _displayPinnedApps = List.from(pinned);
      }
    });
  }

  bool _listMatch(List<AppInfo> list1, List<AppInfo> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].packageName != list2[i].packageName) return false;
    }
    return true;
  }

  Widget buildTile(AppInfo app) {
    String? iconKey = InstalledAppsService.getSavedIconSync(app.packageName);
    IconData iconToShow = icons[iconKey] ?? defaultIcon;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async => await InstalledApps.startApp(app.packageName),

      onLongPress: () {
        AppDialogs.pinnedDialogBox(
          context,
          app,
          _loadApps,
          removeFromPinnedCache,
        );
      },

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(iconToShow, size: 45), const SizedBox(height: 6)],
      ),
    );
    // },
    // );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSearching) {
          setState(() {
            isSearching = false;
            searchController.clear();
            filteredApps = installedApps;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: isAppScreenVisible
                        ? GridView.builder(
                            key: const ValueKey('appScreen'),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.5,
                                ),
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 10,
                            ),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _displayPinnedApps.length,
                            itemBuilder: (context, index) {
                              final app = _displayPinnedApps[index];
                              return buildTile(app);
                            },
                          )
                        : Align(
                            key: const ValueKey('emptyScreen'),
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 30.0,
                                top: 50.0,
                              ),
                              child: StreamBuilder(
                                stream: Stream.periodic(
                                  const Duration(minutes: 1),
                                ),
                                builder: (context, snapshot) {
                                  final now = DateTime.now();
                                  final hour = now.hour.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  final minute = now.minute.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  String formatTime(int t) =>
                                      t.toString().padLeft(2, '0');
                                  final timeString =
                                      "${formatTime(now.hour)}:${formatTime(now.minute)}";
                                  final weekdays = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  final months = [
                                    'Jan',
                                    'Feb',
                                    'Mar',
                                    'Apr',
                                    'May',
                                    'Jun',
                                    'Jul',
                                    'Aug',
                                    'Sep',
                                    'Oct',
                                    'Nov',
                                    'Dec',
                                  ];
                                  final dateString =
                                      "${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}";

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          style: TextStyle(
                                            fontSize: 62,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(2.5, 2.5),
                                                blurRadius: 3,
                                              ),
                                            ],
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                          ),
                                          children: [
                                            TextSpan(text: '$hour:'),
                                            TextSpan(
                                              text:
                                                  minute[0], // first minute digit
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                  221,
                                                  219,
                                                  20,
                                                  6,
                                                ),
                                              ),
                                            ),
                                            TextSpan(
                                              text: minute[1],
                                            ), // second minute digit
                                          ],
                                        ),
                                      ),
                                      // Text(
                                      //   timeString,
                                      //   style: TextStyle(
                                      //     fontSize: 62,
                                      //     fontWeight: FontWeight.bold,
                                      //     letterSpacing: 1.5,
                                      //     shadows: const [
                                      //       Shadow(
                                      //         color: Colors.black26,
                                      //         offset: Offset(2.5, 2.5),
                                      //         blurRadius: 3,
                                      //       ),
                                      //     ],
                                      //     color: Theme.of(
                                      //       context,
                                      //     ).textTheme.bodyMedium?.color,
                                      //   ),
                                      // ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                        ),
                                        child: Text(
                                          dateString,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(1, 1),
                                                blurRadius: 3,
                                              ),
                                            ],
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withOpacity(0.9),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ),

                if (!isSearching)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: IconButton(
                      icon: Image.asset(
                        'assets/wink.png',
                        width: 40,
                        height: 40,
                      ),
                      // icon: const Icon(Icons.apps, size: 36),
                      color: Theme.of(context).iconTheme.color,
                      onPressed: () {
                        setState(() {
                          isAppScreenVisible = !isAppScreenVisible;
                        });
                      },
                    ),
                  ),

                // 2️⃣ Search bar + 3-dot button (bottom) >>>>>
                Padding(
                  key: const ValueKey('searchBar'),
                  padding: const EdgeInsets.only(
                    bottom: 10.0,
                    left: 10.0,
                    right: 10.0,
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
                            focusNode: searchFocusNode,
                            autofocus: false,
                            onTap: () {
                              if (!isSearching) {
                                setState(() => isSearching = true);
                                searchFocusNode.requestFocus();
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
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        // FocusScope.of(context).unfocus();
                                        Future.delayed(
                                          Duration(microseconds: 100),
                                          () {
                                            setState(() {
                                              isSearching = false;
                                              searchController.clear();
                                              filteredApps = installedApps;
                                            });
                                          },
                                        );
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
                                      _loadApps(forceRefresh: true);
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
                top: 40,
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
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onTap: () async {
                          setState(() {
                            isSearching = false;
                            searchController.clear();
                            filteredApps = installedApps;
                          });
                          await InstalledApps.startApp(app.packageName);
                        },
                        onLongPress: () {
                          AppDialogs.appDialogBox(context, app, _loadApps, (
                            app,
                          ) {
                            setState(() {
                              _displayPinnedApps.add(app);
                            });
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
