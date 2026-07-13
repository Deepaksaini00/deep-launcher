import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_service.dart';

enum GlobalAction { setupHome, launcherSettings, refreshApps, exportGridJson, importGridJson }

Future<GlobalAction?> askGlobalAction(BuildContext context) async {
  final themeSvc = Provider.of<ThemeService>(context, listen: false);
  final resolved = themeSvc.resolvedTheme(context);

  return await showModalBottomSheet<GlobalAction>(
    context: context,
    backgroundColor: resolved.dialogColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.grid_view_sharp, color: resolved.iconColor),
              title: Text(
                "Set up home",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.setupHome),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: resolved.iconColor),
              title: Text(
                "Launcher settings",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.launcherSettings),
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: resolved.iconColor),
              title: Text(
                "Refresh apps",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.refreshApps),
            ),
            ListTile(
              leading: Icon(Icons.publish, color: resolved.iconColor),
              title: Text(
                "Export grid",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.exportGridJson),
            ),
            ListTile(
              leading: Icon(Icons.download, color: resolved.iconColor),
              title: Text(
                "Import grid",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.importGridJson),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
