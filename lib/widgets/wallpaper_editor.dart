import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallpaper_service.dart';

class WallpaperEditor extends StatefulWidget {
  final String path;

  const WallpaperEditor({super.key, required this.path});

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
    final previewHeight = MediaQuery.sizeOf(context).height * 0.38;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Wallpaper',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
            onPressed: () {
              final service = Provider.of<WallpaperService>(context, listen: false);
              service.setWallpaper(
                path: widget.path,
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
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
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
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(_frostOpacity),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Drag to position the crop',
                            style: TextStyle(color: Colors.white, fontSize: 12),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text(
                      'Crop zoom: ${_cropScale.toStringAsFixed(1)}×',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.center_focus_strong, size: 18),
                      label: const Text('Center'),
                      onPressed: () => setState(() {
                        _cropX = 0;
                        _cropY = 0;
                      }),
                    ),
                  ],
                ),
                Slider(
                  value: _cropScale,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  label: '${_cropScale.toStringAsFixed(1)}×',
                  onChanged: (value) => setState(() => _cropScale = value),
                ),
                Text(
                  'Horizontal Position: ${(_cropX * 100).round()}%',
                  style: const TextStyle(fontSize: 13),
                ),
                Slider(
                  value: _cropX,
                  min: -1.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) => setState(() => _cropX = value),
                ),
                Text(
                  'Vertical Position: ${(_cropY * 100).round()}%',
                  style: const TextStyle(fontSize: 13),
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
                  secondary: const Icon(Icons.blur_on),
                  title: const Text('Frost/Blur Wallpaper'),
                  subtitle: const Text('Blur and dim the image for better legibility'),
                  value: _frosted,
                  onChanged: (value) => setState(() => _frosted = value),
                ),
                if (_frosted) ...[
                  const SizedBox(height: 10),
                  Text('Blur Amount: ${_frostBlur.round()} px'),
                  Slider(
                    value: _frostBlur,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '${_frostBlur.round()} px',
                    onChanged: (value) => setState(() => _frostBlur = value),
                  ),
                  Text('Tint Opacity: ${(_frostOpacity * 100).round()}%'),
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
    );
  }
}
