import 'package:flutter/material.dart';

import '../../../theme/flcad_colors.dart';

class ProjectDashboard extends StatelessWidget {
  const ProjectDashboard({
    super.key,
    required this.projects,
    required this.photos,
    required this.reconstructions,
  });

  final int projects;
  final int photos;
  final int reconstructions;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Metric(label: 'Projetos', value: projects),
      const SizedBox(width: 8),
      _Metric(label: 'Fotos', value: photos),
      const SizedBox(width: 8),
      _Metric(label: 'Reconstruções', value: reconstructions),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: FLCADColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FLCADColors.border),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: FLCADColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
