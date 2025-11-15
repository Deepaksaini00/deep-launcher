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
            child: const Text('Refresh Apps'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, GlobalAction.exportGridJson),
            child: const Text('Export Grid JSON'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, GlobalAction.importGridJson),
            child: const Text('Import Grid JSON'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, GlobalAction.changeTheme),
            child: const Text('Change Theme'),
          ),
        ],
      );
    },
  );
}
