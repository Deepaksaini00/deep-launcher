import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallpaper_service.dart';
import '../services/theme_service.dart';

class WallpaperEditor extends StatefulWidget {
  final String path;
  final bool isDark;

  const WallpaperEditor({super.key, required this.path, required this.isDark});

  @override
  State<WallpaperEditor> createState() => _WallpaperEditorState();
}

class _WallpaperEditorState extends State<WallpaperEditor> {
  double _cropScale = 1.0;
  double _cropX = 0.0;
  double _cropY = 0.0;
  bool _frosted = false;
  double _frostBlur = 12.0;
  double _frostOpacity = 0.32;

  void _moveCrop(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _cropX = (_cropX - details.delta.dx / (constraints.maxWidth / 2))
          .clamp(-1.0, 1.0);
      _cropY = (_cropY - details.delta.dy / (constraints.maxHeight / 2))
          .clamp(-1.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context).resolvedTheme(context);
    final previewHeight = MediaQuery.sizeOf(context).height * 0.38;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    const accentColor = Color(0xFFBB86FC); // Standard Material Dark theme purple accent

    return Theme(
      data: Theme.of(context).copyWith(
        sliderTheme: SliderThemeData(
          activeTrackColor: accentColor,
          inactiveTrackColor: theme.textColor.withValues(alpha: 0.2),
          thumbColor: accentColor,
          overlayColor: accentColor.withValues(alpha: 0.12),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) return accentColor;
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) return accentColor.withValues(alpha: 0.5);
            return null;
          }),
        ),
      ),
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.textColor),
            tooltip: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit wallpaper',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.check, color: accentColor, size: 20),
              label: const Text(
                'Use wallpaper',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                final service = Provider.of<WallpaperService>(context, listen: false);
                service.setWallpaper(
                  path: widget.path,
                  isDark: widget.isDark,
                  cropScale: _cropScale,
                  cropX: _cropX,
                  cropY: _cropY,
                  frosted: _frosted,
                  frostBlur: _frostBlur,
                  frostOpacity: _frostOpacity,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // PREVIEW BOX
            Container(
              height: previewHeight,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onPanUpdate: (details) => _moveCrop(details, constraints),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRect(
                          child: Transform.scale(
                            scale: _cropScale,
                            alignment: Alignment(_cropX, _cropY),
                            child: Image.file(
                              File(widget.path),
                              fit: BoxFit.cover,
                              alignment: Alignment(_cropX, _cropY),
                            ),
                          ),
                        ),
                        if (_frosted && _frostBlur > 0)
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: _frostBlur,
                                sigmaY: _frostBlur,
                              ),
                              child: Container(
                                color: Colors.black.withValues(alpha: _frostOpacity),
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Drag to position the crop',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // CONTROLS LIST
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 8 + bottomSafeArea),
                children: [
                  // Crop zoom section
                  Text(
                    'Crop zoom: ${_cropScale.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                      fontSize: 15,
                    ),
                  ),
                  Slider(
                    value: _cropScale,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    label: '${_cropScale.toStringAsFixed(1)}x',
                    onChanged: (value) => setState(() => _cropScale = value),
                  ),
                  const SizedBox(height: 8),

                  // Crop position header with Center button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Crop position',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                          fontSize: 15,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.center_focus_strong, size: 18, color: accentColor),
                        label: const Text(
                          'Center',
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => setState(() {
                          _cropX = 0;
                          _cropY = 0;
                        }),
                      ),
                    ],
                  ),
                  Text(
                    'Horizontal: ${(_cropX * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  Slider(
                    value: _cropX,
                    min: -1.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) => setState(() => _cropX = value),
                  ),
                  Text(
                    'Vertical: ${(_cropY * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  Slider(
                    value: _cropY,
                    min: -1.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (value) => setState(() => _cropY = value),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(Icons.blur_on, color: theme.iconColor),
                    title: Text(
                      'Frost the wallpaper',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Blur and tint the image before use',
                      style: TextStyle(
                        color: theme.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    value: _frosted,
                    onChanged: (value) => setState(() => _frosted = value),
                  ),
                  if (_frosted) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Blur Amount: ${_frostBlur.round()} px',
                      style: TextStyle(color: theme.textColor, fontSize: 13),
                    ),
                    Slider(
                      value: _frostBlur,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '${_frostBlur.round()} px',
                      onChanged: (value) => setState(() => _frostBlur = value),
                    ),
                    Text(
                      'Tint Opacity: ${(_frostOpacity * 100).round()}%',
                      style: TextStyle(color: theme.textColor, fontSize: 13),
                    ),
                    Slider(
                      value: _frostOpacity,
                      min: 0.0,
                      max: 0.8,
                      divisions: 16,
                      label: '${(_frostOpacity * 100).round()}%',
                      onChanged: (value) => setState(() => _frostOpacity = value),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
