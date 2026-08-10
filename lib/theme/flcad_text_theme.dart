import 'package:flutter/material.dart';

import 'flcad_colors.dart';

class FLCADTextTheme {
  const FLCADTextTheme._();

  static const TextStyle display = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: FLCADColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: FLCADColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: FLCADColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: FLCADColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: FLCADColors.textSecondary,
  );
}