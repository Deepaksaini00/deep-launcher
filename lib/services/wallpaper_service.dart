import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperService extends ChangeNotifier {
  static const _keyLightPath = 'wallpaper_path_light';
  static const _keyLightScale = 'wallpaper_crop_scale_light';
  static const _keyLightX = 'wallpaper_crop_x_light';
  static const _keyLightY = 'wallpaper_crop_y_light';
  static const _keyLightFrosted = 'wallpaper_frosted_light';
  static const _keyLightBlur = 'wallpaper_frost_blur_light';
  static const _keyLightOpacity = 'wallpaper_frost_opacity_light';

  static const _keyDarkPath = 'wallpaper_path_dark';
  static const _keyDarkScale = 'wallpaper_crop_scale_dark';
  static const _keyDarkX = 'wallpaper_crop_x_dark';
  static const _keyDarkY = 'wallpaper_crop_y_dark';
  static const _keyDarkFrosted = 'wallpaper_frosted_dark';
  static const _keyDarkBlur = 'wallpaper_frost_blur_dark';
  static const _keyDarkOpacity = 'wallpaper_frost_opacity_dark';

  // Backwards compatibility keys
  static const _keyOldPath = 'wallpaper_path';
  static const _keyOldScale = 'wallpaper_crop_scale';
  static const _keyOldX = 'wallpaper_crop_x';
  static const _keyOldY = 'wallpaper_crop_y';
  static const _keyOldFrosted = 'wallpaper_frosted';
  static const _keyOldBlur = 'wallpaper_frost_blur';
  static const _keyOldOpacity = 'wallpaper_frost_opacity';

  String? _lightPath;
  double _lightCropScale = 1.0;
  double _lightCropX = 0.0;
  double _lightCropY = 0.0;
  bool _lightFrosted = false;
  double _lightFrostBlur = 12.0;
  double _lightFrostOpacity = 0.32;

  String? _darkPath;
  double _darkCropScale = 1.0;
  double _darkCropX = 0.0;
  double _darkCropY = 0.0;
  bool _darkFrosted = false;
  double _darkFrostBlur = 12.0;
  double _darkFrostOpacity = 0.32;

  WallpaperService() {
    _loadFromPrefs();
  }

  // Resolvers based on brightness
  String? getPath(bool isDark) {
    if (isDark) return _darkPath ?? _lightPath;
    return _lightPath ?? _darkPath;
  }

  double getCropScale(bool isDark) {
    if (isDark) return _darkPath != null ? _darkCropScale : _lightCropScale;
    return _lightPath != null ? _lightCropScale : _darkCropScale;
  }

  double getCropX(bool isDark) {
    if (isDark) return _darkPath != null ? _darkCropX : _lightCropX;
    return _lightPath != null ? _lightCropX : _darkCropX;
  }

  double getCropY(bool isDark) {
    if (isDark) return _darkPath != null ? _darkCropY : _lightCropY;
    return _lightPath != null ? _lightCropY : _darkCropY;
  }

  bool getFrosted(bool isDark) {
    if (isDark) return _darkPath != null ? _darkFrosted : _lightFrosted;
    return _lightPath != null ? _lightFrosted : _darkFrosted;
  }

  double getFrostBlur(bool isDark) {
    if (isDark) return _darkPath != null ? _darkFrostBlur : _lightFrostBlur;
    return _lightPath != null ? _lightFrostBlur : _darkFrostBlur;
  }

  double getFrostOpacity(bool isDark) {
    if (isDark) return _darkPath != null ? _darkFrostOpacity : _lightFrostOpacity;
    return _lightPath != null ? _lightFrostOpacity : _darkFrostOpacity;
  }

  bool hasWallpaper(bool isDark) {
    final path = getPath(isDark);
    return path != null && File(path).existsSync();
  }

  bool isActiveWallpaperDark(bool isDark) {
    if (isDark) {
      return _darkPath != null || _lightPath == null;
    } else {
      return _lightPath == null && _darkPath != null;
    }
  }

  // Keep single property getters for backwards compatibility
  String? get path => _lightPath ?? _darkPath;
  double get cropScale => _lightCropScale;
  double get cropX => _lightCropX;
  double get cropY => _lightCropY;
  bool get frosted => _lightFrosted;
  double get frostBlur => _lightFrostBlur;
  double get frostOpacity => _lightFrostOpacity;
  bool get hasWallpaperLegacy => (_lightPath ?? _darkPath) != null && File(_lightPath ?? _darkPath!).existsSync();

  Future<void> setWallpaper({
    required String? path,
    required bool isDark,
    double cropScale = 1.0,
    double cropX = 0.0,
    double cropY = 0.0,
    bool frosted = false,
    double frostBlur = 12.0,
    double frostOpacity = 0.32,
  }) async {
    String? finalPath = path;
    if (path != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final suffix = isDark ? 'dark' : 'light';
        final extension = path.split('.').last;
        final savedFile = File('${appDir.path}/wallpaper_$suffix.$extension');
        
        // Remove existing file if any to avoid errors/collisions
        if (savedFile.existsSync()) {
          try {
            savedFile.deleteSync();
          } catch (_) {}
        }
        
        await File(path).copy(savedFile.path);
        finalPath = savedFile.path;
      } catch (e) {
        debugPrint("Error copying wallpaper: $e");
      }
    }

    if (isDark) {
      _darkPath = finalPath;
      _darkCropScale = cropScale;
      _darkCropX = cropX;
      _darkCropY = cropY;
      _darkFrosted = frosted;
      _darkFrostBlur = frostBlur;
      _darkFrostOpacity = frostOpacity;
    } else {
      _lightPath = finalPath;
      _lightCropScale = cropScale;
      _lightCropX = cropX;
      _lightCropY = cropY;
      _lightFrosted = frosted;
      _lightFrostBlur = frostBlur;
      _lightFrostOpacity = frostOpacity;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    if (finalPath == null) {
      await prefs.remove(isDark ? _keyDarkPath : _keyLightPath);
      await prefs.remove(isDark ? _keyDarkScale : _keyLightScale);
      await prefs.remove(isDark ? _keyDarkX : _keyLightX);
      await prefs.remove(isDark ? _keyDarkY : _keyLightY);
      await prefs.remove(isDark ? _keyDarkFrosted : _keyLightFrosted);
      await prefs.remove(isDark ? _keyDarkBlur : _keyLightBlur);
      await prefs.remove(isDark ? _keyDarkOpacity : _keyLightOpacity);
    } else {
      await prefs.setString(isDark ? _keyDarkPath : _keyLightPath, finalPath);
      await prefs.setDouble(isDark ? _keyDarkScale : _keyLightScale, cropScale);
      await prefs.setDouble(isDark ? _keyDarkX : _keyLightX, cropX);
      await prefs.setDouble(isDark ? _keyDarkY : _keyLightY, cropY);
      await prefs.setBool(isDark ? _keyDarkFrosted : _keyLightFrosted, frosted);
      await prefs.setDouble(isDark ? _keyDarkBlur : _keyLightBlur, frostBlur);
      await prefs.setDouble(isDark ? _keyDarkOpacity : _keyLightOpacity, frostOpacity);
    }
  }

  Future<void> clearWallpaper(bool isDark) async {
    await setWallpaper(path: null, isDark: isDark);
  }

  Future<void> clearAll() async {
    await clearWallpaper(false);
    await clearWallpaper(true);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load light wallpaper
    _lightPath = prefs.getString(_keyLightPath);
    if (_lightPath != null) {
      _lightCropScale = prefs.getDouble(_keyLightScale) ?? 1.0;
      _lightCropX = prefs.getDouble(_keyLightX) ?? 0.0;
      _lightCropY = prefs.getDouble(_keyLightY) ?? 0.0;
      _lightFrosted = prefs.getBool(_keyLightFrosted) ?? false;
      _lightFrostBlur = prefs.getDouble(_keyLightBlur) ?? 12.0;
      _lightFrostOpacity = prefs.getDouble(_keyLightOpacity) ?? 0.32;
    }

    // Load dark wallpaper
    _darkPath = prefs.getString(_keyDarkPath);
    if (_darkPath != null) {
      _darkCropScale = prefs.getDouble(_keyDarkScale) ?? 1.0;
      _darkCropX = prefs.getDouble(_keyDarkX) ?? 0.0;
      _darkCropY = prefs.getDouble(_keyDarkY) ?? 0.0;
      _darkFrosted = prefs.getBool(_keyDarkFrosted) ?? false;
      _darkFrostBlur = prefs.getDouble(_keyDarkBlur) ?? 12.0;
      _darkFrostOpacity = prefs.getDouble(_keyDarkOpacity) ?? 0.32;
    }

    // Migration logic for old wallpaper path key
    final oldPath = prefs.getString(_keyOldPath);
    if (oldPath != null) {
      _lightPath = oldPath;
      _lightCropScale = prefs.getDouble(_keyOldScale) ?? 1.0;
      _lightCropX = prefs.getDouble(_keyOldX) ?? 0.0;
      _lightCropY = prefs.getDouble(_keyOldY) ?? 0.0;
      _lightFrosted = prefs.getBool(_keyOldFrosted) ?? false;
      _lightFrostBlur = prefs.getDouble(_keyOldBlur) ?? 12.0;
      _lightFrostOpacity = prefs.getDouble(_keyOldOpacity) ?? 0.32;
      
      // Save migrated settings as light wallpaper and clear old
      await setWallpaper(
        path: _lightPath,
        isDark: false,
        cropScale: _lightCropScale,
        cropX: _lightCropX,
        cropY: _lightCropY,
        frosted: _lightFrosted,
        frostBlur: _lightFrostBlur,
        frostOpacity: _lightFrostOpacity,
      );
      
      await prefs.remove(_keyOldPath);
      await prefs.remove(_keyOldScale);
      await prefs.remove(_keyOldX);
      await prefs.remove(_keyOldY);
      await prefs.remove(_keyOldFrosted);
      await prefs.remove(_keyOldBlur);
      await prefs.remove(_keyOldOpacity);
    }

    notifyListeners();
  }
}
