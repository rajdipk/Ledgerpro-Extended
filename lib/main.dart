// main.dart
// ignore_for_file: use_key_in_widget_constructors, unused_import

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart'; 
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'screens/authentication_screen.dart';
import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'providers/business_provider.dart'; 
import 'providers/currency_provider.dart'; 
import 'providers/theme_provider.dart';
import 'screens/settings.dart';
import 'mannuals/user_manual_screen.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;

        // Initialize window manager
        await windowManager.ensureInitialized();
        
        WindowOptions windowOptions = const WindowOptions(
          size: Size(1200, 800),
          minimumSize: Size(800, 600),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.normal,
        );
        
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      }

      // Initialize package_info_plus
      await PackageInfo.fromPlatform();

      // Initialize database
      await DatabaseHelper.instance.database;

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BusinessProvider()), 
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
            // Add other providers if needed
          ],
          child: const MyApp(),
        ),
      );
    } catch (error) {
      debugPrint('Error during initialization: $error');
      // Show a user-friendly error screen instead of crashing
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'Unable to start the application.\nPlease try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LedgerPro',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/auth',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/auth':
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AuthenticationScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 800),
                );
              case '/home':
                return PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 800),
                );
              default:
                return MaterialPageRoute(builder: (_) => AuthenticationScreen());
            }
          },
          routes: {
            '/auth': (context) => AuthenticationScreen(),
            '/home': (context) => HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/user-manual': (context) => const UserManualScreen(),
          },
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                physics: const BouncingScrollPhysics(),
                scrollbars: true,
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
