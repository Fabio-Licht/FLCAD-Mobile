import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/professional_surface_models.dart';

class ProfessionalSurfaceRepository {
  const ProfessionalSurfaceRepository(this.projectDirectory);
  final Directory projectDirectory;

  File get _state => File(
    path.join(projectDirectory.path, 'Surfaces', 'professional-surfaces.json'),
  );

  Future<void> saveAll(
    Iterable<ProfessionalSurfaceDefinition> definitions,
  ) async {
    await _state.parent.create(recursive: true);
    final committed = definitions
        .where((surface) => surface.status == SurfaceFeatureStatus.committed)
        .map((surface) => surface.toJson())
        .toList();
    await _state.writeAsString(
      jsonEncode({
        'version': 1,
        'surfaces': committed,
        'history': committed
            .map(
              (surface) => {
                'featureId': surface['id'],
                'revision': surface['revision'],
                'tool': surface['tool'],
                'references': surface['references'],
                'updatedAt': surface['updatedAt'],
              },
            )
            .toList(),
      }),
      flush: true,
    );
  }

  Future<List<ProfessionalSurfaceDefinition>> loadAll() async {
    if (!await _state.exists()) return const [];
    final root = Map<String, dynamic>.from(
      jsonDecode(await _state.readAsString()) as Map,
    );
    return (root['surfaces'] as List? ?? const [])
        .map(
          (value) => ProfessionalSurfaceDefinition.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
  }
}
