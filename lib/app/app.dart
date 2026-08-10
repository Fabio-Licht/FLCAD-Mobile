import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../theme/flcad_theme.dart';

class FLCADApp extends StatelessWidget {
  const FLCADApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLCAD Mobile',
      debugShowCheckedModeBanner: false,
      theme: FLCADTheme.dark(),
      home: const HomeScreen(),
    );
  }
}