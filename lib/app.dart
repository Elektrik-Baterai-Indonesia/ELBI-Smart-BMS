import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/monitoring/monitoring_demo_screen.dart';
import 'features/settings/app_settings_controller.dart';
import 'features/splash/splash_screen.dart';

class BmsApp extends StatefulWidget {
  const BmsApp({super.key});

  static const _previewMonitoringPage = bool.fromEnvironment(
    'BMS_PREVIEW_MONITORING',
  );

  @override
  State<BmsApp> createState() => _BmsAppState();
}

class _BmsAppState extends State<BmsApp> {
  late final AppSettingsController _settingsController;
  Timer? _splashTimer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _settingsController = AppSettingsController()..load();
    _splashTimer = Timer(SplashScreen.duration, () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: _settingsController,
      child: AnimatedBuilder(
        animation: _settingsController,
        builder: (context, _) => MaterialApp(
          title: 'ELBI Smart BMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _settingsController.themeMode,
          locale: Locale(_settingsController.language.languageCode),
          supportedLocales: const [Locale('en'), Locale('id')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSystemUiOverlayStyle
                : AppTheme.systemUiOverlayStyle,
            child: child!,
          ),
          home: _showSplash
              ? const SplashScreen()
              : BmsApp._previewMonitoringPage
              ? const MonitoringDemoScreen()
              : const HomeScreen(),
        ),
      ),
    );
  }
}
