import 'package:android_launcher/icons/app_icons.dart';
import 'package:android_launcher/services/installed_apps.dart';
import 'package:android_launcher/services/theme_service.dart';
import 'package:android_launcher/widgets/app_system_icon.dart';
import 'package:android_launcher/widgets/dialog_box.dart';
import 'package:android_launcher/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:provider/provider.dart';

class HomeSetupSheet extends StatefulWidget {
  final List<AppInfo> installedApps;
  final List<AppInfo> pinnedApps;
  final VoidCallback onRefresh;
  final int gridColumns;
  final int gridRows;

  const HomeSetupSheet({
    super.key,
    required this.installedApps,
    required this.pinnedApps,
    required this.onRefresh,
    required this.gridColumns,
    required this.gridRows,
  });

  @override
  State<HomeSetupSheet> createState() => _HomeSetupSheetState();
}

class _HomeSetupSheetState extends State<HomeSetupSheet> {
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';
  late List<AppInfo> _localPinnedApps;
  List<Map<String, dynamic>> _shortcuts = [];

  @override
  void initState() {
    super.initState();
    _localPinnedApps = List.from(widget.pinnedApps);
    _loadShortcuts();
  }

  void _loadShortcuts() async {
    final list = await InstalledAppsService.getCustomShortcuts();
    if (mounted) {
      setState(() {
        _shortcuts = list;
      });
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context, listen: false).resolvedTheme(context);

    return DefaultTabController(
      length: 3,
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.88,
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            TabBar(
              labelColor: theme.textColor,
              unselectedLabelColor: theme.textColor.withValues(alpha: 0.6),
              indicatorColor: theme.iconColor,
              tabs: const [
                Tab(icon: Icon(Icons.add), text: 'Add'),
                Tab(icon: Icon(Icons.drag_handle), text: 'Arrange'),
                Tab(icon: Icon(Icons.link), text: 'Shortcuts'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAddTab(context, theme),
                  _buildArrangeTab(context, theme),
                  _buildShortcutsTab(context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTab(BuildContext context, AppTheme theme) {
    final filtered = widget.installedApps
        .where((app) => app.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _filterController,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.search, color: theme.iconColor),
              hintText: 'Search apps',
              hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.6)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.textColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.iconColor),
              ),
            ),
            onChanged: (value) => setState(() => _filter = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final app = filtered[index];
              final isOnGrid = _localPinnedApps.any((item) => item.packageName == app.packageName);
              
              String? iconKey = InstalledAppsService.getSavedIconSync(app.packageName);
              IconData iconToShow = icons[iconKey] ?? Icons.apps;

              return CheckboxListTile(
                activeColor: theme.iconColor,
                checkColor: theme.background,
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AppSystemIcon(
                      packageName: app.packageName,
                      fallback: iconToShow,
                      iconColor: Colors.black87,
                    ),
                  ),
                ),
                value: isOnGrid,
                title: Text(
                  app.name,
                  style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  app.packageName,
                  style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onChanged: (checked) async {
                  if (checked == true) {
                    await InstalledAppsService.addToPinned(app);
                    setState(() {
                      if (!_localPinnedApps.any((item) => item.packageName == app.packageName)) {
                        _localPinnedApps.add(app);
                      }
                    });
                  } else {
                    await InstalledAppsService.removePinned(app.packageName);
                    setState(() {
                      _localPinnedApps.removeWhere((item) => item.packageName == app.packageName);
                    });
                  }
                  widget.onRefresh();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArrangeTab(BuildContext context, AppTheme theme) {
    final maxVisible = widget.gridColumns * widget.gridRows;
    final visibleCount = _localPinnedApps.length > maxVisible ? maxVisible : _localPinnedApps.length;

    if (visibleCount == 0) {
      return Center(
        child: Text(
          'Home is empty',
          style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            'Long press, then drag over a tile to move into its spot.',
            style: TextStyle(color: theme.textColor.withValues(alpha: 0.8), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visibleCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.gridColumns,
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final app = _localPinnedApps[index];
              return DragTarget<String>(
                key: ValueKey('arrange-target-${app.packageName}'),
                onWillAcceptWithDetails: (details) {
                  if (details.data == app.packageName) {
                    return false;
                  }
                  final oldIndex = _localPinnedApps.indexWhere(
                    (gridItem) => gridItem.packageName == details.data,
                  );
                  final targetIndex = _localPinnedApps.indexWhere(
                    (gridItem) => gridItem.packageName == app.packageName,
                  );
                  if (oldIndex >= 0 && targetIndex >= 0) {
                    setState(() {
                      final item = _localPinnedApps.removeAt(oldIndex);
                      _localPinnedApps.insert(targetIndex, item);
                    });
                    // Instantly notify parent home screen
                    InstalledAppsService.updatePinnedAppsOrder(_localPinnedApps).then((_) {
                      widget.onRefresh();
                    });
                  }
                  return true;
                },
                builder: (context, candidateData, __) {
                  Widget buildTileWidget({bool isDropTarget = false}) {
                    String? iconKey = InstalledAppsService.getSavedIconSync(app.packageName);
                    IconData iconToShow = icons[iconKey] ?? Icons.apps;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDropTarget
                            ? theme.iconColor.withValues(alpha: 0.2)
                            : theme.textColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: isDropTarget
                            ? Border.all(color: theme.iconColor, width: 2)
                            : Border.all(color: theme.textColor.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconToShow, size: 24, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    app.name,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: Icon(Icons.palette_outlined, size: 18, color: theme.iconColor),
                              tooltip: 'Choose icon',
                              onPressed: () {
                                AppDialogs.iconDialogBox(context, app, () {
                                  // Refresh icons
                                  setState(() {});
                                  widget.onRefresh();
                                });
                              },
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: Icon(Icons.remove_circle_outline, size: 18, color: Colors.redAccent.withValues(alpha: 0.9)),
                              tooltip: 'Remove from home',
                              onPressed: () async {
                                await InstalledAppsService.removePinned(app.packageName);
                                setState(() {
                                  _localPinnedApps.removeWhere((item) => item.packageName == app.packageName);
                                });
                                widget.onRefresh();
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return LongPressDraggable<String>(
                    key: ValueKey('arrange-drag-${app.packageName}'),
                    data: app.packageName,
                    onDragEnd: (_) async {
                      await InstalledAppsService.updatePinnedAppsOrder(_localPinnedApps);
                      widget.onRefresh();
                    },
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width * (0.88 / widget.gridColumns),
                        child: buildTileWidget(),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: buildTileWidget(),
                    ),
                    child: buildTileWidget(isDropTarget: candidateData.isNotEmpty),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ===== NEW SHORTCUTS TAB AND DIALOGS =====
  Widget _buildShortcutsTab(BuildContext context, AppTheme theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.iconColor,
              foregroundColor: theme.background,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Custom Shortcut',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showAddShortcutDialog(context, theme),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _shortcuts.isEmpty
              ? Center(
                  child: Text(
                    'No custom shortcuts added yet',
                    style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _shortcuts.length,
                  itemBuilder: (context, index) {
                    final shortcut = _shortcuts[index];
                    final String packageName = shortcut["packageName"];
                    final String name = shortcut["name"];
                    final String url = packageName.replaceFirst('shortcut:', '');

                    final isOnGrid = _localPinnedApps.any((item) => item.packageName == packageName);
                    final String? iconKey = InstalledAppsService.getSavedIconSync(packageName);
                    final IconData iconToShow = icons[iconKey] ?? Icons.link;

                    return CheckboxListTile(
                      activeColor: theme.iconColor,
                      checkColor: theme.background,
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.9)),
                            onPressed: () async {
                              await InstalledAppsService.deleteCustomShortcut(packageName);
                              _loadShortcuts();
                              widget.onRefresh();
                            },
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconToShow, size: 22, color: Colors.black87),
                          ),
                        ],
                      ),
                      value: isOnGrid,
                      title: Text(
                        name,
                        style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        url,
                        style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (checked) async {
                        final app = AppInfo.create({
                          "name": name,
                          "package_name": packageName,
                          "version_name": "1.0.0",
                          "version_code": 1,
                          "platform_type": "android",
                          "installed_timestamp": 0,
                          "is_system_app": false,
                          "is_launchable_app": true,
                        });
                        if (checked == true) {
                          await InstalledAppsService.addToPinned(app);
                          setState(() {
                            if (!_localPinnedApps.any((item) => item.packageName == packageName)) {
                              _localPinnedApps.add(app);
                            }
                          });
                        } else {
                          await InstalledAppsService.removePinned(packageName);
                          setState(() {
                            _localPinnedApps.removeWhere((item) => item.packageName == packageName);
                          });
                        }
                        widget.onRefresh();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddShortcutDialog(BuildContext context, AppTheme theme) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    String selectedIconKey = 'web';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.dialogColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Add Custom Shortcut",
                style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        labelText: "Name / Label",
                        labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.6)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: theme.textColor.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: theme.iconColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: urlController,
                      style: TextStyle(color: theme.textColor),
                      decoration: InputDecoration(
                        labelText: "URL / Deep Link",
                        labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.6)),
                        hintText: "example.com",
                        hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.3)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: theme.textColor.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: theme.iconColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Icon:",
                          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showIconPickerNested(context, theme, (pickedKey) {
                              setDialogState(() {
                                selectedIconKey = pickedKey;
                              });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.textColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icons[selectedIconKey] ?? Icons.web_outlined,
                                  color: theme.iconColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedIconKey,
                                  style: TextStyle(color: theme.textColor, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.9)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.iconColor,
                    foregroundColor: theme.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final url = urlController.text.trim();
                    if (name.isNotEmpty && url.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      await InstalledAppsService.addCustomShortcut(name, url, selectedIconKey);
                      navigator.pop();
                      _loadShortcuts();
                      widget.onRefresh();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showIconPickerNested(
    BuildContext context,
    AppTheme theme,
    void Function(String) onPicked,
  ) async {
    final picked = await showIconPicker(context, defaultCount: 36);
    if (picked == null || picked == kUseOriginalIcon) return;
    onPicked(picked);
  }
}
