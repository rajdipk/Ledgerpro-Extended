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
        debugPrint('Initializing for desktop platform...');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        debugPrint('SQLite FFI initialized');

        // Initialize window manager
        debugPrint('Initializing window manager...');
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
        debugPrint('Window manager initialized');
      }

      // Initialize package_info_plus
      debugPrint('Initializing package info...');
      await PackageInfo.fromPlatform();
      debugPrint('Package info initialized');

      // Initialize database
      debugPrint('Initializing database...');
      await DatabaseHelper.instance.database;
      debugPrint('Database initialized');

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
    } catch (error, stackTrace) {
      debugPrint('Error during initialization: $error');
      debugPrint('Stack trace:\n$stackTrace');
      
      // Show a more detailed error screen
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to start the application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please try again later or contact support.',
                    textAlign: TextAlign.center,
                  ),
                ],
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
