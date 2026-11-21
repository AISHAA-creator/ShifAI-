import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF00307A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0A4A9E);
  static const secondary = Color(0xFF0A4A9E);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF9EC5E0);
  static const secondaryFixed = Color(0xFFCBE6FF);
  static const tertiary = Color(0xFF003F0B);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF005914);
  static const tertiaryFixed = Color(0xFFA3F69C);
  static const surface = Color(0xFFF4F6FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF42474F);
  static const outline = Color(0xFF72777F);
  static const outlineVariant = Color(0xFFC2C7D0);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const amber50 = Color(0xFFFFFBEB);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const amber800 = Color(0xFF92400E);
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);
  static const rose200 = Color(0xFFFECDD3);

  static const navy = primary;
  static const accentBlue = secondaryContainer;
  static const buttonBlue = primary;
  static const cream = surface;
  static const creamCard = surfaceContainerLowest;
  static const pastel = surfaceContainerLow;
  static const pastelBorder = outlineVariant;
  static const text = onSurface;
  static const gray = onSurfaceVariant;
  static const safe = emerald700;
  static const safeBg = emerald50;
  static const safeText = emerald800;
  static const warning = amber600;
  static const warningBg = amber50;
  static const warningText = amber800;
  static const danger = error;
  static const dangerBg = errorContainer;
  static const dangerText = onErrorContainer;
  static const gold = warning;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double screenHorizontal = 20;
}

class AppRadii {
  AppRadii._();

  static const double card = 16;
  static const double bigCard = 24;
  static const double input = 12;
  static const double pill = 999;
}
