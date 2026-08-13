import 'package:flutter/material.dart';

import '../../../../models/project.dart';
import '../../../../theme/flcad_colors.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onNewProject,
  });

  final Project project;
  final VoidCallback onNewProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FLCADColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FLCADColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Projeto Atual",
            style: TextStyle(color: FLCADColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            project.name,
            style: const TextStyle(
              color: FLCADColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.client,
            style: const TextStyle(color: FLCADColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            project.description,
            style: const TextStyle(color: FLCADColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onNewProject,
            icon: const Icon(Icons.add),
            label: const Text("Novo Projeto"),
          ),
        ],
      ),
    );
  }
}
