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

  // Define 4-5 themes here
  static const List<AppTheme> themes = [
    AppTheme(
      id: 'light',
      name: 'Light',
      background: Color.fromARGB(255, 251, 252, 255),
      iconColor: Colors.black87,
      textColor: Colors.black87,
      dialogColor: Color.fromARGB(255, 193, 194, 195),
    ),
    AppTheme(
      id: 'dark',
      name: 'Dark',
      background: Color(0xFF263238),
      iconColor: Color(0xFFECEFF1),
      textColor: Color(0xFFECEFF1),
      dialogColor: Color(0xFF37474F),
    ),
    AppTheme(
      id: 'blue',
      name: 'Blue',
      background: Color(0xFF0F1724),
      iconColor: Color.fromARGB(255, 231, 245, 255),
      textColor: Color(0xFFFFFFFF),
      dialogColor: Color.fromARGB(255, 39, 50, 67),
    ),
    AppTheme(
      id: 'warm',
      name: 'Warm',
      background: Color.fromARGB(255, 99, 64, 46),
      iconColor: Color.fromARGB(255, 231, 245, 255),
      textColor: Color.fromARGB(255, 219, 225, 230),
      dialogColor: Color.fromARGB(255, 88, 68, 38),
    ),
    AppTheme(
      id: 'green',
      name: 'Green',
      background: Color.fromARGB(255, 8, 48, 35),
      iconColor: Color.fromARGB(255, 254, 255, 255),
      textColor: Color.fromARGB(255, 252, 243, 243),
      dialogColor: Color.fromARGB(255, 13, 68, 50),
    ),
    AppTheme(
      id: 'softGrey',
      name: 'Soft Grey',
      background: Color(0xFFD9D9D9),
      iconColor: Colors.black87,
      textColor: Colors.black87,
      dialogColor: Color(0xFFCFCFCF),
    ),
    AppTheme(
      id: 'solarizedLight',
      name: 'Solarized Light',
      background: Color(0xFFFDF6E3),
      iconColor: Color.fromARGB(255, 43, 55, 59),
      textColor: Color.fromARGB(255, 43, 55, 59),
      dialogColor: Color(0xFFEEE8D5),
    ),
    AppTheme(
      id: 'black',
      name: 'Black',
      background: Color.fromARGB(255, 6, 6, 6),
      iconColor: Color.fromARGB(221, 237, 237, 237),
      textColor: Color.fromARGB(221, 255, 255, 255),
      dialogColor: Color.fromARGB(255, 128, 128, 128),
    ),
  ];

  late AppTheme _current;

  ThemeService() {
    _current = themes[0];
    _loadFromPrefs();
  }

  AppTheme get current => _current;

  AppTheme themeById(String id) =>
      themes.firstWhere((t) => t.id == id, orElse: () => themes[0]);

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
