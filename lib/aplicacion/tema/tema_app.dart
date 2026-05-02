import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF121826);
  static const muted = Color(0xFF667085);
  static const canvas = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFCF5);
  static const surfaceTint = Color(0xFFF8FBFF);
  static const border = Color(0xFFE3E8EF);
  static const teal = Color(0xFF00A693);
  static const tealDark = Color(0xFF05645D);
  static const coral = Color(0xFFF06449);
  static const amber = Color(0xFFF3B43F);
  static const leaf = Color(0xFF2EAB6F);
  static const violet = Color(0xFF6557E8);
  static const navy = Color(0xFF172033);
  static const navySoft = Color(0xFF25324A);
  static const sky = Color(0xFF2FA7E0);
  static const blue = Color(0xFF2F6FED);
}

class AppShadows {
  static List<BoxShadow> soft(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.12),
        blurRadius: 26,
        offset: const Offset(0, 14),
      ),
    ];
  }

  static List<BoxShadow> lifted(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.20),
        blurRadius: 36,
        offset: const Offset(0, 18),
      ),
    ];
  }

  static List<BoxShadow> crisp(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }
}

class AppGradients {
  static const LinearGradient command = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.navy,
      AppColors.navySoft,
      AppColors.tealDark,
    ],
  );

  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEFFAF8),
      Color(0xFFF8FBFF),
      Color(0xFFFFF8EA),
    ],
  );

  static const LinearGradient action = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.teal,
      AppColors.blue,
    ],
  );
}
