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
import 'package:flutter/material.dart';
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

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();

  List<AppInfo> installedApps = [];
  List<AppInfo> filteredApps = [];
  List<AppInfo> pinnedApps = [];
  List<AppInfo> _displayPinnedApps = [];

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
    _loadApps();
    InstalledAppsService.printPinnedAppsPretty();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
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
    final theme = Provider.of<ThemeService>(context, listen: false).resolvedTheme(context);
    String? iconKey = InstalledAppsService.getSavedIconSync(app.packageName);
    IconData iconToShow = icons[iconKey] ?? defaultIcon;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

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
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                iconToShow,
                size: 28,
                color: theme.iconColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: theme.textColor,
              ),
            ),
          ),
        ],
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
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
                          alignment: Alignment(wallpaper.cropX, wallpaper.cropY),
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
                            color: Colors.black.withOpacity(wallpaper.frostOpacity),
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
                      // Left: Large empty space
                      const Expanded(
                        flex: 6,
                        child: SizedBox(),
                      ),
                      // Right: Two-column vertical app layout
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, right: 15, bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: wallpaper.hasWallpaper ? 10 : 0,
                                sigmaY: wallpaper.hasWallpaper ? 10 : 0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: wallpaper.hasWallpaper
                                      ? theme.background.withValues(
                                          alpha: isDark ? 0.4 : 0.3,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  border: wallpaper.hasWallpaper
                                      ? Border.all(
                                          color: theme.textColor.withValues(alpha: 0.15),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                padding: wallpaper.hasWallpaper
                                    ? const EdgeInsets.all(12)
                                    : EdgeInsets.zero,
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 15,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: _displayPinnedApps.length,
                                  itemBuilder: (context, index) {
                                    final app = _displayPinnedApps[index];
                                    return buildTile(app);
                                  },
                                ),
                              ),
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
                                  color: theme.textColor.withValues(alpha: 0.15),
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
                                case GlobalAction.refreshApps:
                                  _loadApps(forceRefresh: true);
                                  break;
                                case GlobalAction.exportGridJson:
                                  final String? json =
                                      await InstalledAppsService.exportPinnedApps();
                                  if (json != null) {
                                    await GridAppPicker.saveFileToLocalStorage(json);
                                  }
                                  break;
                                case GlobalAction.importGridJson:
                                  final jsonFile = await GridAppPicker.pickJsonFile();
                                  if (jsonFile != null) {
                                    await InstalledAppsService.importPinnedApps(jsonFile);
                                    _loadApps();
                                  }
                                  break;
                                case GlobalAction.changeTheme:
                                  if (context.mounted) {
                                    await showThemePickerDialog(context);
                                  }
                                  break;
                                case GlobalAction.selectWallpaper:
                                  if (context.mounted) {
                                    await _pickAndOpenWallpaperEditor(context);
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
                              AppDialogs.appDialogBox(
                                context,
                                app,
                                _loadApps,
                              );
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result == null || result.files.single.path == null) return;

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WallpaperEditor(path: result.files.single.path!),
        ),
      );
    } catch (e) {
      // ignore
    }
  }
}
