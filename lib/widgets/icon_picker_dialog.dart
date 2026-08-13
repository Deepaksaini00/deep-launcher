import 'package:android_launcher/icons/app_icons.dart';
import 'package:android_launcher/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sentinel returned by [showIconPicker] when the user asks to use the app's
/// original (black & white) icon instead of a library icon.
const String kUseOriginalIcon = '__use_original__';

/// Opens the icon picker dialog. Returns the selected icon slug, null when
/// dismissed, or [kUseOriginalIcon] when the user resets to the app icon.
Future<String?> showIconPicker(
  BuildContext context, {
  String? selectedKey,
  int defaultCount = 36,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _IconPickerDialog(
      selectedKey: selectedKey,
      defaultCount: defaultCount,
    ),
  );
}

class _IconPickerDialog extends StatefulWidget {
  const _IconPickerDialog({this.selectedKey, this.defaultCount = 36});

  final String? selectedKey;
  final int defaultCount;

  @override
  State<_IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<_IconPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<MapEntry<String, IconData>> get _visibleIcons {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      final preferred = <MapEntry<String, IconData>>[];
      final seen = <String>{};
      for (final key in preferredIconKeys) {
        final data = icons[key];
        if (data != null && seen.add(key)) {
          preferred.add(MapEntry(key, data));
        }
      }
      // Top up with a few more from the full set if needed.
      for (final e in icons.entries) {
        if (preferred.length >= widget.defaultCount) break;
        if (seen.add(e.key)) preferred.add(e);
      }
      return preferred;
    }
    return icons.entries
        .where((e) => e.key.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(
      context,
      listen: false,
    ).resolvedTheme(context);
    final visible = _visibleIcons;

    return Dialog(
      backgroundColor: theme.dialogColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  "Pick an icon",
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  tooltip: 'Use original icon',
                  icon: const Icon(Icons.brightness_6_outlined),
                  color: theme.iconColor,
                  onPressed: () => Navigator.pop(context, kUseOriginalIcon),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              autofocus: false,
              style: TextStyle(color: theme.textColor),
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: theme.iconColor),
                hintText: "Search icons",
                hintStyle:
                    TextStyle(color: theme.textColor.withValues(alpha: 0.5)),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.textColor.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.iconColor),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _query.isEmpty
                    ? '${visible.length} icons'
                    : '${visible.length} matches',
                style: TextStyle(
                  color: theme.textColor.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: GridView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: visible.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final entry = visible[index];
                  final isSelected = entry.key == widget.selectedKey;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, entry.key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.iconColor.withValues(alpha: 0.35)
                            : theme.textColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        entry.value,
                        size: 28,
                        color: theme.textColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
