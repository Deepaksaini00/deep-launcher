import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:android_launcher/main.dart';
import 'package:android_launcher/services/theme_service.dart';
import 'package:android_launcher/services/wallpaper_service.dart';

void main() {
  testWidgets('Launcher home screen rendering smoke test', (WidgetTester tester) async {
    // Build our app under MultiProvider and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => WallpaperService()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the search bar widget is displayed
    expect(find.byKey(const ValueKey('searchBar')), findsOneWidget);
  });
}
