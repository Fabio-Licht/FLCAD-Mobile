import 'package:flutter/material.dart';

import 'flcad_colors.dart';

class FLCADTheme {
  const FLCADTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: FLCADColors.background,

      colorScheme: const ColorScheme.dark(
        primary: FLCADColors.primary,
        surface: FLCADColors.surface,
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: FLCADColors.background,
        foregroundColor: FLCADColors.textPrimary,
        elevation: 0,
      ),

      cardColor: FLCADColors.surface,

      dividerColor: FLCADColors.border,
    );
  }
}
