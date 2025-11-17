import 'package:flutter/material.dart';

enum GlobalAction { refreshApps, exportGridJson, importGridJson, changeTheme }

Future<GlobalAction?> askGlobalAction(BuildContext context) async {
  return await showDialog<GlobalAction>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, GlobalAction.refreshApps),
            child: Text(
              "Refresh Apps",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, GlobalAction.exportGridJson),
            child: Text(
              "Export Grid JSON",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, GlobalAction.importGridJson),
            child: Text(
              "Import Grid JSON",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, GlobalAction.changeTheme),
            child: Text(
              "Change Theme",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      );
    },
  );
}
