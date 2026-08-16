import 'package:flutter/material.dart';

abstract final class DesktopThemeManager {
  static ThemeData dark() => _build(
    Brightness.dark,
    const Color(0xff39bdf8),
    const Color(0xff0b111a),
    const Color(0xff121b27),
  );
  static ThemeData light() => _build(
    Brightness.light,
    const Color(0xff0067b8),
    const Color(0xfff3f7fb),
    const Color(0xffffffff),
  );

  static ThemeData _build(
    Brightness brightness,
    Color primary,
    Color background,
    Color surface,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Segoe UI',
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: surface,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
