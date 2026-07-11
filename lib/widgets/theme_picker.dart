//  --- Theme picker show the Dialog Box to select a theme only shows the background color of theme ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

Future<void> showThemePickerDialog(BuildContext context) async {
  final themeSvc = Provider.of<ThemeService>(context, listen: false);
  final currentId = themeSvc.current.id;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Choose Theme'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ThemeService.themes.map((appTheme) {
              final bool isSelected = appTheme.id == currentId;
              return GestureDetector(
                onTap: () {
                  // Set theme and close dialog
                  themeSvc.setTheme(appTheme.id);
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 66,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(width: 3, color: Colors.black87)
                            : Border.all(
                                width: 1,
                                color: const Color.fromARGB(66, 23, 23, 23),
                              ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.black26, blurRadius: 6)]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: appTheme.id == 'system'
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      color: ThemeService.lightTheme.background,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: ThemeService.darkTheme.background,
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                color: appTheme.background,
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 64,
                      child: Text(
                        appTheme.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeSvc.resolvedTheme(context).textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
