import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Store Icons for 12 apps...
  List<IconData?> homeIcons = List.filled(12, null);

  // Search Controller..
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var columnCount = 2;
    var minRowCountOnScreen = 6; // You have 12 items, 2 columns = 6 rows

    // Calculate aspect ratio to fit all items on screen
    var aspectRatio =
        (size.width / columnCount) / (size.height / minRowCountOnScreen);

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Column(
        // alignment: Alignment.center,
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
                children: List.generate(
                  12,
                  (index) => Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.add, size: 25.0),
                  ),
                ),
              ),
            ),
          ),

          // 2️⃣ Search bar + 3-dot button (bottom) >>>>>
          Padding(
            padding: const EdgeInsets.only(bottom: 1.0, left: 10, right: 10),
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


