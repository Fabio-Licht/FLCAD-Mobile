import 'dart:io';

import 'package:flutter/material.dart';

import '../../../theme/flcad_colors.dart';
import '../models/project_status.dart';
import '../models/project_summary.dart';

class ProjectSummaryCard extends StatelessWidget {
  const ProjectSummaryCard({
    super.key,
    required this.project,
    required this.onOpen,
    this.isCurrent = false,
    this.onFavorite,
    this.onArchive,
    this.onDelete,
  });

  final ProjectSummary project;
  final VoidCallback onOpen;
  final bool isCurrent;
  final VoidCallback? onFavorite;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final thumbnail = project.thumbnailPath;
    return Card(
      color: FLCADColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: thumbnail == null
                    ? const ColoredBox(
                        color: FLCADColors.background,
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: Icon(Icons.engineering),
                        ),
                      )
                    : Image.file(
                        File(thumbnail),
                        width: 72,
                        height: 72,
                        cacheWidth: 144,
                        cacheHeight: 144,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 72,
                          height: 72,
                          child: Icon(Icons.broken_image),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrent)
                      const Text(
                        'PROJETO ATUAL',
                        style: TextStyle(
                          fontSize: 11,
                          color: FLCADColors.primary,
                        ),
                      ),
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cliente: ${project.client}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${project.photoCount} fotos • ${project.status.label}',
                      style: const TextStyle(color: FLCADColors.textSecondary),
                    ),
                    Text(
                      'Modificado: ${_date(project.lastModifiedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: FLCADColors.textSecondary,
                      ),
                    ),
                    if (project.status == ProjectStatus.processing) ...[
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: project.reconstructionProgress,
                      ),
                      Text(
                        '${(project.reconstructionProgress * 100).round()}% • ${project.currentReconstructionStep ?? 'Preparando'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                    if (isCurrent)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          '▶ Continuar Projeto',
                          style: TextStyle(
                            color: FLCADColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onFavorite != null || onArchive != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'favorite') onFavorite?.call();
                    if (value == 'archive') onArchive?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (onFavorite != null)
                      PopupMenuItem(
                        value: 'favorite',
                        child: Text(
                          project.isFavorite ? 'Desafixar' : 'Favoritar',
                        ),
                      ),
                    if (onArchive != null)
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Arquivar/restaurar'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                  ],
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
