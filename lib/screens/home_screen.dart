import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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
  final GlobalKey _searchBarKey = GlobalKey();
  double _searchBarHeight = 56;

  void removeFromPinnedCache(String packageName) {
    setState(() {
      pinnedApps.removeWhere((a) => a.packageName == packageName);
      _displayPinnedApps.removeWhere((a) => a.packageName == packageName);
    });
  }

  List<AppInfo> _getSortedApps(List<AppInfo> apps, String query) {
    if (query.isEmpty) {
      final sorted = List<AppInfo>.from(apps);
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return sorted;
    }
    final sorted = List<AppInfo>.from(apps);
    sorted.sort((a, b) {
      final scoreA = _getMatchScore(a.name, query);
      final scoreB = _getMatchScore(b.name, query);
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  int _getMatchScore(String appName, String query) {
    final nameLower = appName.toLowerCase();
    final queryLower = query.toLowerCase();

    // 1. Exact match
    if (nameLower == queryLower) {
      return 100;
    }

    // 2. Starts with query
    if (nameLower.startsWith(queryLower)) {
      return 90;
    }

    // 3. Word starts with query
    final words = nameLower.split(RegExp(r'[\s\-_]+'));
    for (final word in words) {
      if (word.startsWith(queryLower)) {
        return 80;
      }
    }

    // 4. Contains query
    if (nameLower.contains(queryLower)) {
      return 70;
    }

    // 5. Subsequence match (characters in order, like f-i-r in Flipkart)
    int queryIdx = 0;
    for (int i = 0; i < nameLower.length; i++) {
      if (queryIdx < queryLower.length &&
          nameLower.codeUnitAt(i) == queryLower.codeUnitAt(queryIdx)) {
        queryIdx++;
      }
    }
    if (queryIdx == queryLower.length) {
      return 50;
    }

    // 6. Overlap score (how many characters of query exist in name)
    int overlapCount = 0;
    final queryChars = queryLower.split('').toSet();
    for (final char in queryChars) {
      if (nameLower.contains(char)) {
        overlapCount++;
      }
    }
    if (overlapCount > 0) {
      return (overlapCount * 30 / queryChars.length).round();
    }

    return 0;
  }

  void _measureSearchBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = _searchBarKey.currentContext?.size;
      if (size != null && size.height > 0 && size.height != _searchBarHeight) {
        setState(() {
          _searchBarHeight = size.height;
        });
      }
    });
  }

  void _onSearchFocusChange() {
    if (searchFocusNode.hasFocus) {
      if (!isSearching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              isSearching = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                searchFocusNode.requestFocus();
                _measureSearchBar();
              }
            });
          }
        });
      }
    } else {
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
      if (isSearching && isCurrentRoute) {
        _requestSearchExit();
      }
    }
  }

  void _requestSearchExit() {
    _finishSearchExit();
  }

  void _finishSearchExit() {
    if (!mounted) return;
    setState(() {
      isSearching = false;
      searchController.clear();
      filteredApps = installedApps;
    });
  }

  // The cross/cancel button should leave the app-list screen right away,
  // without waiting for the keyboard to close.
  void _exitSearchImmediately() {
    _finishSearchExit();
    searchFocusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    searchFocusNode.addListener(_onSearchFocusChange);
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

  double _topPadding = 0.0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_topPadding == 0.0) {
      _topPadding = MediaQuery.of(context).padding.top;
    }
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        gridColumns = prefs.getInt('home_grid_columns') ?? 2;
        gridRows = (prefs.getInt('home_grid_rows') ?? 6).clamp(1, 7);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    searchFocusNode.removeListener(_onSearchFocusChange);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    try {
      final locale = PlatformDispatcher.instance.locale.toString();
      return DateFormat.yMMMMd(locale).format(dt);
    } catch (_) {
      return DateFormat.yMMMMd('en_US').format(dt);
    }
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
        filteredApps = _getSortedApps(
          apps,
          isSearching ? searchController.text : '',
        );
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
    String? iconKey = InstalledAppsService.getSavedIconSync(app.packageName);
    IconData iconToShow = icons[iconKey] ?? defaultIcon;

    final iconBgColor = Colors.white.withValues(alpha: 0.65);
    final double tileBgSize = gridColumns == 3 ? 65 : 74;
    final double iconSize = gridColumns == 3 ? 30 : 34;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async => await InstalledAppsService.startApp(app.packageName),
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
          width: tileBgSize,
          height: tileBgSize,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Center(
            child: Icon(iconToShow, size: iconSize, color: Colors.black87),
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
    final isDark = theme.id == 'dark';

    final bool useDarkText = wallpaper.hasWallpaper(isDark)
        ? !wallpaper.isActiveWallpaperDark(isDark)
        : !isDark;

    // Keyboard/inset info. When the search keyboard is open it should sit
    // flush against the keyboard; otherwise the search bar keeps the same
    // bottom margin as on the home screen.
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final double searchBarBottomGap = (isSearching && keyboardInset > 0)
        ? 0.0
        : 16.0;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: useDarkText
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: useDarkText
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    int displayHour = _currentTime.hour;
    if (!use24Hour) {
      displayHour = displayHour % 12;
      if (displayHour == 0) displayHour = 12;
    }
    final hourStr = displayHour.toString().padLeft(2, '0');
    final minuteStr = _currentTime.minute.toString().padLeft(2, '0');
    final clockColor = isDark ? Colors.white : Colors.black;

    final String locale = PlatformDispatcher.instance.locale.toString();
    String weekdayName;
    try {
      weekdayName = DateFormat.EEEE(locale).format(_currentTime);
    } catch (_) {
      weekdayName = DateFormat.EEEE('en_US').format(_currentTime);
    }

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
          searchFocusNode.unfocus();
          // back navigation
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: null,
        body: Stack(
          children: [
            // 1. Wallpaper Background
            if (wallpaper.hasWallpaper(isDark))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRect(
                      child: Transform.scale(
                        scale: wallpaper.getCropScale(isDark),
                        alignment: Alignment(
                          wallpaper.getCropX(isDark),
                          wallpaper.getCropY(isDark),
                        ),
                        child: Image.file(
                          File(wallpaper.getPath(isDark)!),
                          fit: BoxFit.cover,
                          alignment: Alignment(
                            wallpaper.getCropX(isDark),
                            wallpaper.getCropY(isDark),
                          ),
                        ),
                      ),
                    ),
                    if (wallpaper.getFrosted(isDark) &&
                        wallpaper.getFrostBlur(isDark) > 0)
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: wallpaper.getFrostBlur(isDark),
                            sigmaY: wallpaper.getFrostBlur(isDark),
                          ),
                          child: Container(
                            color: Colors.black.withValues(
                              alpha: wallpaper.getFrostOpacity(isDark),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // 1.5. Top Status Bar Blur Background
            if (wallpaper.hasWallpaper(isDark)) // && !isSearching)
              Positioned(
                top: -5,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).padding.top + 8,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.80),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.textColor.withValues(alpha: 0.40),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 2. Home Screen Content (Clock + Pinned Apps) - shown only on the
            //    home screen; fully replaced by the app-list screen while
            //    searching so the grid/time never appear in the background.
            if (!isSearching)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 0,
                right: 0,
                bottom: _searchBarHeight + 30,
                child: IgnorePointer(
                  ignoring: isSearching,
                  child: Opacity(
                    opacity: isSearching ? 0.0 : 1.0,
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).removeViewInsets(removeBottom: true),
                      child: Row(
                        children: [
                          // Left: Time and date display
                          Expanded(
                            flex: leftFlex,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              hourStr,
                                              style: TextStyle(
                                                fontSize: 64,
                                                fontWeight: FontWeight.bold,
                                                color: clockColor,
                                                height: 0.9,
                                              ),
                                            ),
                                            Text(
                                              minuteStr,
                                              style: TextStyle(
                                                fontSize: 64,
                                                fontWeight: FontWeight.bold,
                                                color: clockColor,
                                                height: 0.9,
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            // Date Pill
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                  sigmaX: 4,
                                                  sigmaY: 4,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.15,
                                                              )
                                                        : Colors.black
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _formatDate(_currentTime),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            // Today's [Weekday]
                                            Text(
                                              "Today's\n$weekdayName",
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                height: 1.15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Dummy search bar spacing
                                // SizedBox(height: _searchBarHeight + 16.0),
                              ],
                            ),
                          ),

                          // Right: Two-column vertical app layout
                          Expanded(
                            flex: rightFlex,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    // alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 10,
                                        bottom: 10,
                                        left: 0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: GridView.builder(
                                          // GridView.builder creates default padding for elements
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: gridColumns,
                                                crossAxisSpacing: 10,
                                                mainAxisSpacing: 12,
                                                childAspectRatio: 1.0,
                                              ),
                                          itemCount: visiblePinnedApps.length,
                                          itemBuilder: (context, index) {
                                            final app =
                                                visiblePinnedApps[index];
                                            return buildTile(app);
                                          },
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
                    ),
                  ),
                ),
              ),

            // 3a. Full-screen Blur Background (visible when searching): the blur
            //     layer covers the whole screen, including the area behind and
            //     below the search bar.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Visibility(
                visible: isSearching,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Material(
                      color: theme.background.withValues(
                        alpha: wallpaper.hasWallpaper(isDark)
                            ? (isDark ? 0.45 : 0.35)
                            : 0.95,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3b. App List (visible when searching): structurally confined to
            //     end exactly at the search bar top border (plus a small safety
            //     margin) so app names can never render below or behind the
            //     search bar.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: isSearching
                  ? keyboardInset + _searchBarHeight + searchBarBottomGap + 4
                  : 0,
              child: Visibility(
                visible: isSearching,
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).padding.top + 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        border: Border(
                          bottom: BorderSide(
                            color: theme.textColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        reverse: searchController.text.isNotEmpty,
                        padding: const EdgeInsets.only(top: 10, bottom: 12),
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            title: Text(
                              app.name,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () async {
                              searchFocusNode.unfocus();
                              await InstalledAppsService.startApp(
                                app.packageName,
                              );
                            },
                            onLongPress: () {
                              AppDialogs.appDialogBox(context, app, _loadApps);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Search Bar + 3-dot Button (bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboardInset,
              child: Padding(
                key: const ValueKey('searchBar'),
                padding: EdgeInsets.fromLTRB(
                  10.0,
                  0.0,
                  10.0,
                  searchBarBottomGap,
                ),
                child: ClipRRect(
                  key: _searchBarKey,
                  borderRadius: BorderRadius.circular(50.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: wallpaper.hasWallpaper(isDark) ? 10 : 0,
                      sigmaY: wallpaper.hasWallpaper(isDark) ? 10 : 0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSearching
                            ? (isDark
                                  ? Colors.black.withValues(alpha: 0.20)
                                  : Colors.grey.withValues(alpha: 0.35))
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: isSearching
                            ? BorderRadius.zero
                            : BorderRadius.circular(50.0),
                        border: (!isSearching && wallpaper.hasWallpaper(isDark))
                            ? Border.all(
                                color: theme.textColor.withValues(alpha: 0.15),
                                width: 1,
                              )
                            : null,
                      ),
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        style: TextStyle(color: theme.textColor),
                        onChanged: (query) {
                          setState(() {
                            filteredApps = _getSortedApps(installedApps, query);
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
                                _exitSearchImmediately();
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndOpenWallpaperEditor(
    BuildContext context, {
    required bool isDark,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) {
        debugPrint("File picking canceled or returned no files.");
        return;
      }
      final path = result.files.single.path;
      if (path == null) {
        debugPrint("Picked file path is null.");
        return;
      }

      if (!context.mounted) {
        debugPrint("Context is not mounted when opening wallpaper editor.");
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (editorContext) =>
              WallpaperEditor(path: path, isDark: isDark),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint("Error in _pickAndOpenWallpaperEditor: $e\n$stackTrace");
    }
  }

  void _showWallpaperOptionsDialog(BuildContext context) {
    final theme = Provider.of<ThemeService>(
      context,
      listen: false,
    ).resolvedTheme(context);
    final wallpaper = Provider.of<WallpaperService>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.dialogColor,
          title: Text(
            'Wallpaper Settings',
            style: TextStyle(color: theme.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.wb_sunny_outlined, color: theme.iconColor),
                title: Text(
                  'Pick Light Wallpaper',
                  style: TextStyle(color: theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _pickAndOpenWallpaperEditor(context, isDark: false);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.nightlight_round_outlined,
                  color: theme.iconColor,
                ),
                title: Text(
                  'Pick Dark Wallpaper',
                  style: TextStyle(color: theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _pickAndOpenWallpaperEditor(context, isDark: true);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.redAccent),
                title: Text(
                  'Clear Light Wallpaper',
                  style: TextStyle(color: theme.textColor),
                ),
                onTap: () async {
                  await wallpaper.clearWallpaper(false);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.redAccent),
                title: Text(
                  'Clear Dark Wallpaper',
                  style: TextStyle(color: theme.textColor),
                ),
                onTap: () async {
                  await wallpaper.clearWallpaper(true);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'Clear All Wallpapers',
                  style: TextStyle(color: theme.textColor),
                ),
                onTap: () async {
                  await wallpaper.clearAll();
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLauncherSettings(BuildContext context) {
    final theme = Provider.of<ThemeService>(
      context,
      listen: false,
    ).resolvedTheme(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.dialogColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: theme.iconColor,
                    ),
                    title: Text(
                      "Change Theme",
                      style: TextStyle(color: theme.textColor),
                    ),
                    onTap: () {
                      Navigator.pop(modalContext);
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
                      Navigator.pop(modalContext);
                      _showWallpaperOptionsDialog(context);
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
                          7,
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
