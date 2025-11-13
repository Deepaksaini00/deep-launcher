import 'package:android_launcher/services/installed_apps.dart';
import 'package:android_launcher/widgets/dialog_box.dart';
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
  }

  void _loadApps() async {
    var apps = await InstalledAppsService.getInstalledApps();
    var pinned = await InstalledAppsService.getPinnedApps();
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      installedApps = apps;
      filteredApps = apps;
      pinnedApps = pinned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
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
                      bottom: 20,
                      top: 55,
                    ),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    physics: NeverScrollableScrollPhysics(), // Add this line
                    childAspectRatio: 1.5, // Add this line
                    children: List.generate(pinnedApps.length, (index) {
                      final app = pinnedApps[index];
                      return GestureDetector(
                        onTap: () async =>
                            await InstalledApps.startApp(app.packageName),
                        onLongPress: () => dialogBox(context, app),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.apps,
                              size: 40,
                              color: Color.fromARGB(255, 187, 178, 178),
                            ),

                            const SizedBox(height: 5),
                            // Container(
                            //   padding: const EdgeInsets.all(10.0),
                            //   margin: const EdgeInsets.all(4.0),
                            // ),
                          ],
                        ),
                      );
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
                          onTap: () {
                            setState(() => isSearching = true);
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
                                          size: 26, // adjust as needed
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 40),

                            hintText: 'Search App ${installedApps.length}',
                            hintStyle: TextStyle(
                              color: const Color.fromARGB(230, 28, 28, 28),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Color.fromARGB(253, 0, 0, 0),
                              ),
                              onPressed: () {
                                // 3- dot working do it later....
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
                color: Colors.blueGrey.withOpacity(0.95),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 30),
                  itemCount: filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    return ListTile(
                      title: Text(
                        app.name,
                        style: const TextStyle(color: Colors.black),
                      ),
                      onTap: () async {
                        await InstalledApps.startApp(app.packageName);
                      },
                      onLongPress: () {
                        dialogBox(context, app);
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
