import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  final String id;
  final String name;
  final Color background;
  final Color iconColor;
  final Color textColor;
  final Color dialogColor;

  const AppTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.iconColor,
    required this.textColor,
    required this.dialogColor,
  });
}

class ThemeService extends ChangeNotifier {
  static const _prefsKey = 'selected_theme_id';

  static const AppTheme lightTheme = AppTheme(
    id: 'light',
    name: 'Light',
    background: Color.fromARGB(255, 251, 252, 255),
    iconColor: Colors.black87,
    textColor: Colors.black87,
    dialogColor: Color.fromARGB(255, 230, 230, 230),
  );

  static const AppTheme darkTheme = AppTheme(
    id: 'dark',
    name: 'Dark',
    background: Color.fromARGB(255, 18, 18, 18),
    iconColor: Colors.white70,
    textColor: Colors.white,
    dialogColor: Color.fromARGB(255, 30, 30, 30),
  );

  static const AppTheme systemTheme = AppTheme(
    id: 'system',
    name: 'System Default',
    background: Color.fromARGB(255, 128, 128, 128),
    iconColor: Colors.grey,
    textColor: Colors.grey,
    dialogColor: Color.fromARGB(255, 100, 100, 100),
  );

  static const List<AppTheme> themes = [
    lightTheme,
    darkTheme,
    systemTheme,
  ];

  late AppTheme _current;

  ThemeService() {
    _current = systemTheme;
    _loadFromPrefs();
  }

  AppTheme get current => _current;

  AppTheme resolvedTheme(BuildContext context) {
    if (_current.id == 'system') {
      final brightness = MediaQuery.platformBrightnessOf(context);
      return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
    return _current;
  }

  AppTheme resolvedThemeForBrightness(Brightness brightness) {
    if (_current.id == 'system') {
      return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
    return _current;
  }

  AppTheme themeById(String id) =>
      themes.firstWhere((t) => t.id == id, orElse: () => systemTheme);

  Future<void> setTheme(String id) async {
    _current = themeById(id);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefsKey);
    if (id != null) {
      _current = themeById(id);
      notifyListeners();
    }
  }
}
