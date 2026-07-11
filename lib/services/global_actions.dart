import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_service.dart';

enum GlobalAction { refreshApps, exportGridJson, importGridJson, changeTheme, selectWallpaper }

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
              leading: Icon(Icons.refresh, color: resolved.iconColor),
              title: Text(
                "Refresh Apps",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.refreshApps),
            ),
            ListTile(
              leading: Icon(Icons.file_upload, color: resolved.iconColor),
              title: Text(
                "Export Grid JSON",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.exportGridJson),
            ),
            ListTile(
              leading: Icon(Icons.file_download, color: resolved.iconColor),
              title: Text(
                "Import Grid JSON",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.importGridJson),
            ),
            ListTile(
              leading: Icon(Icons.palette_outlined, color: resolved.iconColor),
              title: Text(
                "Change Theme",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.changeTheme),
            ),
            ListTile(
              leading: Icon(Icons.wallpaper, color: resolved.iconColor),
              title: Text(
                "Choose Wallpaper",
                style: TextStyle(color: resolved.textColor),
              ),
              onTap: () => Navigator.pop(context, GlobalAction.selectWallpaper),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
