import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';

/// Loads and renders an installed app's original icon. When [grayscale] is
/// true the icon is shown in black & white (used as the default on the home
/// grid). Falls back to [fallback] while loading or for shortcuts.
class AppSystemIcon extends StatefulWidget {
  final String packageName;
  final double size;
  final IconData fallback;
  final Color iconColor;
  final bool grayscale;

  const AppSystemIcon({
    super.key,
    required this.packageName,
    this.size = 22,
    required this.fallback,
    required this.iconColor,
    this.grayscale = false,
  });

  @override
  State<AppSystemIcon> createState() => _AppSystemIconState();
}

class _AppSystemIconState extends State<AppSystemIcon> {
  static final Map<String, Uint8List?> _iconCache = {};
  bool _loading = false;
  Uint8List? _iconBytes;

  static const List<double> _grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(AppSystemIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _iconBytes = null;
      _loading = false;
      _loadIcon();
    }
  }

  void _loadIcon() async {
    final pkg = widget.packageName;
    if (pkg.startsWith('shortcut:')) {
      return;
    }
    if (_iconCache.containsKey(pkg)) {
      if (mounted) {
        setState(() {
          _iconBytes = _iconCache[pkg];
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final app = await InstalledApps.getAppInfo(pkg);
      if (app != null && app.icon != null) {
        _iconCache[pkg] = app.icon;
        if (mounted) {
          setState(() {
            _iconBytes = app.icon;
            _loading = false;
          });
        }
      } else {
        _iconCache[pkg] = null;
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    } catch (_) {
      _iconCache[pkg] = null;
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildIcon() {
    if (_iconBytes != null) {
      final image = Image.memory(
        _iconBytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
      if (widget.grayscale) {
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
          child: image,
        );
      }
      return image;
    }
    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Padding(
          padding: EdgeInsets.all(widget.size * 0.18),
          child: const CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }
    return Icon(widget.fallback, size: widget.size, color: widget.iconColor);
  }

  @override
  Widget build(BuildContext context) {
    return _buildIcon();
  }
}
