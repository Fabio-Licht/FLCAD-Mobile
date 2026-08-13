import 'package:flutter/material.dart';

import '../../theme/flcad_colors.dart';
import '../../theme/flcad_text_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FLCAD', style: FLCADTextTheme.title),
              const SizedBox(height: 4),
              Text('Engineering Intelligence', style: FLCADTextTheme.caption),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded, color: FLCADColors.textPrimary),
        ),
      ],
    );
  }
}
