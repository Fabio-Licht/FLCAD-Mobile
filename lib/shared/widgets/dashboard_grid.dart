import 'package:flutter/material.dart';

import 'flcad_card.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        const FLCADCard(icon: Icons.folder_open_rounded, title: 'Projetos'),

        FLCADCard(
          icon: Icons.document_scanner_rounded,
          title: 'Scanner',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Crie um projeto antes de iniciar o scanner.'),
              ),
            );
          },
        ),

        const FLCADCard(icon: Icons.auto_awesome_rounded, title: 'IA'),

        const FLCADCard(icon: Icons.settings_rounded, title: 'Configurações'),
      ],
    );
  }
}
