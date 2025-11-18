import 'package:android_launcher/screens/home_screen.dart';
import 'package:android_launcher/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeService(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themSvc, _) {
        final them = themSvc.current;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Deep Launcher",
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: them.background,
            dialogTheme: DialogThemeData(backgroundColor: them.dialogColor),

            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: them.textColor,
              displayColor: them.textColor,
            ),
            iconTheme: IconThemeData(color: them.iconColor),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
