import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:android_launcher/icons/app_icons.dart';
import 'package:android_launcher/services/global_actions.dart';
import 'package:android_launcher/services/installed_apps.dart';
import 'package:android_launcher/services/theme_service.dart';
import 'package:android_launcher/services/wallpaper_service.dart';
import 'package:android_launcher/util/file_picker.dart';
import 'package:android_launcher/widgets/dialog_box.dart';
import 'package:android_launcher/widgets/theme_picker.dart';
import 'package:android_launcher/widgets/wallpaper_editor.dart';
import 'package:android_launcher/widgets/home_setup_sheet.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool isSearching = false;
  List<IconData?> homeIcons = List.filled(12, null);
  IconData defaultIcon = Icons.apps;

  int gridColumns = 2;
  int gridRows = 6;

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  List<AppInfo> installedApps = [];
  List<AppInfo> filteredApps = [];
  List<AppInfo> pinnedApps = [];
  List<AppInfo> _displayPinnedApps = [];
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  void removeFromPinnedCache(String packageName) {
    setState(() {
      pinnedApps.removeWhere((a) => a.packageName == packageName);
      _displayPinnedApps.removeWhere((a) => a.packageName == packageName);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadApps();
    InstalledAppsService.printPinnedAppsPretty();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        gridColumns = prefs.getInt('home_grid_columns') ?? 2;
        gridRows = prefs.getInt('home_grid_rows') ?? 6;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final day = dt.day;
    String suffix = 'th';
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }

    const months = [
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
      'Dec'
    ];
    final monthStr = months[dt.month - 1];

    return '$day$suffix. $monthStr, ${dt.year}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadApps(forceRefresh: true);
    }
  }

  void _loadApps({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await InstalledAppsService.refreshInstalledApps();
    }
    var apps = await InstalledAppsService.getInstalledApps();
    var pinned = await InstalledAppsService.getPinnedApps();
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    for (final app in pinned) {
      await InstalledAppsService.getSavedIcon(app.packageName);
    }

    if (mounted) {
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
  }

  bool _listMatch(List<AppInfo> list1, List<AppInfo> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].packageName != list2[i].packageName) return false;
    }
    return true;
  }

  Widget buildTile(AppInfo app) {
    final theme = Provider.of<ThemeService>(
      context,
      listen: false,
    ).resolvedTheme(context);
    String? iconKey = InstalledAppsService.getSavedIconSync(app.packageName);
    IconData iconToShow = icons[iconKey] ?? defaultIcon;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.65);

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
      child: Center(
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(iconToShow, size: 28, color: theme.iconColor),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Provider.of<ThemeService>(context).resolvedTheme(context);
    final wallpaper = Provider.of<WallpaperService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int displayHour = _currentTime.hour % 12;
    if (displayHour == 0) displayHour = 12;
    final hourStr = displayHour.toString().padLeft(2, '0');
    final minuteStr = _currentTime.minute.toString().padLeft(2, '0');
    final clockColor = isDark ? const Color(0xFF8CD8A2) : const Color(0xFF2E7D32);

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final weekdayName = weekdays[_currentTime.weekday - 1];

    int leftFlex = 6;
    int rightFlex = 5;
    if (gridColumns == 1) {
      leftFlex = 8;
      rightFlex = 3;
    } else if (gridColumns == 3) {
      leftFlex = 5;
      rightFlex = 6;
    }

    final maxVisibleApps = gridColumns * gridRows;
    final visiblePinnedApps = _displayPinnedApps.length > maxVisibleApps
        ? _displayPinnedApps.sublist(0, maxVisibleApps)
        : _displayPinnedApps;

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
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: null,
        body: Stack(
          children: [
            // 1. Wallpaper Background
            if (wallpaper.hasWallpaper)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: Transform.scale(
                        scale: wallpaper.cropScale,
                        alignment: Alignment(wallpaper.cropX, wallpaper.cropY),
                        child: Image.file(
                          File(wallpaper.path!),
                          fit: BoxFit.cover,
                          alignment: Alignment(
                            wallpaper.cropX,
                            wallpaper.cropY,
                          ),
                        ),
                      ),
                    ),
                    if (wallpaper.frosted && wallpaper.frostBlur > 0)
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: wallpaper.frostBlur,
                            sigmaY: wallpaper.frostBlur,
                          ),
                          child: Container(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(
                              wallpaper.frostOpacity,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // 2. Main Content
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Left: Time and date display
                      Expanded(
                        flex: leftFlex,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              bottom: 10,
                              right: 5,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stacked hour & minute
                                  Text(
                                    hourStr,
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 1.8
                                        ..color = clockColor,
                                      height: 0.9,
                                    ),
                                  ),
                                  Text(
                                    minuteStr,
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 1.8
                                        ..color = clockColor,
                                      height: 0.9,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  // Date Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      _formatDate(_currentTime),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textColor.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  // Today's [Weekday]
                                  Text(
                                    "Today's\n$weekdayName.",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textColor,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right: Two-column vertical app layout
                      Expanded(
                        flex: rightFlex,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 15,
                              bottom: 20,
                              left: 10,
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridColumns,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount: visiblePinnedApps.length,
                              itemBuilder: (context, index) {
                                final app = visiblePinnedApps[index];
                                return buildTile(app);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar + 3-dot Button (bottom)
                Padding(
                  key: const ValueKey('searchBar'),
                  padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: wallpaper.hasWallpaper ? 10 : 0,
                        sigmaY: wallpaper.hasWallpaper ? 10 : 0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: wallpaper.hasWallpaper
                              ? theme.background.withValues(
                                  alpha: isDark ? 0.45 : 0.35,
                                )
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.08)),
                          borderRadius: BorderRadius.circular(50.0),
                          border: wallpaper.hasWallpaper
                              ? Border.all(
                                  color: theme.textColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: TextField(
                          controller: searchController,
                          focusNode: searchFocusNode,
                          style: TextStyle(color: theme.textColor),
                          onTap: () {
                            if (!isSearching) {
                              setState(() => isSearching = true);
                              searchFocusNode.requestFocus();
                            }
                          },
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
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            hintText: 'Search Apps ${installedApps.length}',
                            hintStyle: TextStyle(
                              color: theme.textColor.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isSearching ? Icons.close : Icons.more_vert,
                                color: theme.iconColor,
                              ),
                              onPressed: () async {
                                if (isSearching) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    isSearching = false;
                                    searchController.clear();
                                    filteredApps = installedApps;
                                  });
                                } else {
                                  final action = await askGlobalAction(context);
                                  if (action == null) return;
                                  switch (action) {
                                    case GlobalAction.setupHome:
                                      if (context.mounted) {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => HomeSetupSheet(
                                            installedApps: installedApps,
                                            pinnedApps: pinnedApps,
                                            onRefresh: _loadApps,
                                            gridColumns: gridColumns,
                                            gridRows: gridRows,
                                          ),
                                        );
                                      }
                                      break;
                                    case GlobalAction.launcherSettings:
                                      if (context.mounted) {
                                        _showLauncherSettings(context);
                                      }
                                      break;
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
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 3. Search Results Overlay (visible when searching)
            if (isSearching)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 80,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: theme.background.withValues(
                        alpha: wallpaper.hasWallpaper
                            ? (isDark ? 0.45 : 0.35)
                            : 0.95,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 20, bottom: 30),
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          return ListTile(
                            title: Text(
                              app.name,
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.w500,
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
                              AppDialogs.appDialogBox(context, app, _loadApps);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndOpenWallpaperEditor(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              WallpaperEditor(path: result.files.single.path!),
        ),
      );
    } catch (e) {
      // ignore
    }
  }

  Future<void> _showLauncherSettings(BuildContext context) {
    final theme = Provider.of<ThemeService>(context, listen: false).resolvedTheme(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.dialogColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: theme.iconColor),
                    title: Text(
                      "Change Theme",
                      style: TextStyle(color: theme.textColor),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showThemePickerDialog(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.wallpaper, color: theme.iconColor),
                    title: Text(
                      "Choose Wallpaper",
                      style: TextStyle(color: theme.textColor),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndOpenWallpaperEditor(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.grid_on, color: theme.iconColor),
                    title: Text(
                      "Home grid columns",
                      style: TextStyle(color: theme.textColor),
                    ),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: gridColumns,
                        dropdownColor: theme.dialogColor,
                        style: TextStyle(color: theme.textColor),
                        items: List.generate(
                          3,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              '${index + 1} Column${index > 0 ? 's' : ''}',
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                        ),
                        onChanged: (val) async {
                          if (val != null) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('home_grid_columns', val);
                            setModalState(() {
                              gridColumns = val;
                            });
                            setState(() {
                              gridColumns = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.grid_3x3, color: theme.iconColor),
                    title: Text(
                      "Home grid rows",
                      style: TextStyle(color: theme.textColor),
                    ),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: gridRows,
                        dropdownColor: theme.dialogColor,
                        style: TextStyle(color: theme.textColor),
                        items: List.generate(
                          9,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              '${index + 1} Row${index > 0 ? 's' : ''}',
                              style: TextStyle(color: theme.textColor),
                            ),
                          ),
                        ),
                        onChanged: (val) async {
                          if (val != null) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('home_grid_rows', val);
                            setModalState(() {
                              gridRows = val;
                            });
                            setState(() {
                              gridRows = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
