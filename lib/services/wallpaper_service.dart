import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperService extends ChangeNotifier {
  static const _keyPath = 'wallpaper_path';
  static const _keyScale = 'wallpaper_crop_scale';
  static const _keyX = 'wallpaper_crop_x';
  static const _keyY = 'wallpaper_crop_y';
  static const _keyFrosted = 'wallpaper_frosted';
  static const _keyBlur = 'wallpaper_frost_blur';
  static const _keyOpacity = 'wallpaper_frost_opacity';

  String? _path;
  double _cropScale = 1.0;
  double _cropX = 0.0;
  double _cropY = 0.0;
  bool _frosted = false;
  double _frostBlur = 12.0;
  double _frostOpacity = 0.32;

  WallpaperService() {
    _loadFromPrefs();
  }

  String? get path => _path;
  double get cropScale => _cropScale;
  double get cropX => _cropX;
  double get cropY => _cropY;
  bool get frosted => _frosted;
  double get frostBlur => _frostBlur;
  double get frostOpacity => _frostOpacity;

  bool get hasWallpaper => _path != null && File(_path!).existsSync();

  Future<void> setWallpaper({
    required String? path,
    double cropScale = 1.0,
    double cropX = 0.0,
    double cropY = 0.0,
    bool frosted = false,
    double frostBlur = 12.0,
    double frostOpacity = 0.32,
  }) async {
    _path = path;
    _cropScale = cropScale;
    _cropX = cropX;
    _cropY = cropY;
    _frosted = frosted;
    _frostBlur = frostBlur;
    _frostOpacity = frostOpacity;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyPath);
      await prefs.remove(_keyScale);
      await prefs.remove(_keyX);
      await prefs.remove(_keyY);
      await prefs.remove(_keyFrosted);
      await prefs.remove(_keyBlur);
      await prefs.remove(_keyOpacity);
    } else {
      await prefs.setString(_keyPath, path);
      await prefs.setDouble(_keyScale, cropScale);
      await prefs.setDouble(_keyX, cropX);
      await prefs.setDouble(_keyY, cropY);
      await prefs.setBool(_keyFrosted, frosted);
      await prefs.setDouble(_keyBlur, frostBlur);
      await prefs.setDouble(_keyOpacity, frostOpacity);
    }
  }

  Future<void> clearWallpaper() async {
    await setWallpaper(path: null);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _path = prefs.getString(_keyPath);
    if (_path != null) {
      _cropScale = prefs.getDouble(_keyScale) ?? 1.0;
      _cropX = prefs.getDouble(_keyX) ?? 0.0;
      _cropY = prefs.getDouble(_keyY) ?? 0.0;
      _frosted = prefs.getBool(_keyFrosted) ?? false;
      _frostBlur = prefs.getDouble(_keyBlur) ?? 12.0;
      _frostOpacity = prefs.getDouble(_keyOpacity) ?? 0.32;
      notifyListeners();
    }
  }
}
