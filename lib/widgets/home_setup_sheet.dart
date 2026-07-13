import 'package:android_launcher/icons/app_icons.dart';
import 'package:android_launcher/services/installed_apps.dart';
import 'package:android_launcher/services/theme_service.dart';
import 'package:android_launcher/widgets/dialog_box.dart';
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

  @override
  void initState() {
    super.initState();
    _localPinnedApps = List.from(widget.pinnedApps);
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
      length: 2,
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
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAddTab(context, theme),
                  _buildArrangeTab(context, theme),
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
                    color: theme.textColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconToShow, size: 22, color: theme.iconColor),
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
                                    color: theme.textColor.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconToShow, size: 24, color: theme.iconColor),
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
}
