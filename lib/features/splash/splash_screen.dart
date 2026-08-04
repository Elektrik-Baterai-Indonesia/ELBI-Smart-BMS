import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle,
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Center(child: _SplashContent())),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(
            image: AssetImage('assets/icon/elbi_smart_bms_icon.png'),
            width: 74,
            height: 74,
          ),
          SizedBox(height: 9),
          Text(
            'ELBI Smart BMS',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'by Elektrik Baterai Indonesia',
            style: TextStyle(color: AppColors.text, fontSize: 13, height: 1),
          ),
        ],
      ),
    );
  }
}
