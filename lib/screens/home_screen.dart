import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Search Controller..
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0, left: 10, right: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 1.3),
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search App',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 13.0,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // later: open 3-dot menu (popup)
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

















//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Deep Launcher',
//       home: InstalledAppsScreen(),
//     );
//   }
// }

// class InstalledAppsScreen extends StatefulWidget {
//   const InstalledAppsScreen({super.key});

//   @override
//   State<InstalledAppsScreen> createState() => _InstalledAppsScreenState();
// }

// class _InstalledAppsScreenState extends State<InstalledAppsScreen> {
//   List<AppInfo> apps = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadInstalledApps(); // directly call load function
//   }

//   /// Fetch installed apps (user + system)
//   Future<void> _loadInstalledApps() async {
//     setState(() => isLoading = true);

//     List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
//       excludeSystemApps: true,
//       excludeNonLaunchableApps: true,
//       withIcon: false,
//     );

//     setState(() {
//       apps = installedApps;
//       isLoading = false;
//     });
//   }


