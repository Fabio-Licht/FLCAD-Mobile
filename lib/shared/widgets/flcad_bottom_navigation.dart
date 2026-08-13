import 'package:flutter/material.dart';

import '../../theme/flcad_colors.dart';

class FLCADBottomNavigation extends StatelessWidget {
  const FLCADBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: FLCADColors.surface,
      indicatorColor: FLCADColors.primary.withValues(alpha: 0.15),
      selectedIndex: 0,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Projetos',
        ),
        NavigationDestination(
          icon: Icon(Icons.document_scanner_outlined),
          selectedIcon: Icon(Icons.document_scanner),
          label: 'Scanner',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'IA',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Config.',
        ),
      ],
    );
  }
}
