import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../graph/generated_surface_graph.dart';
import '../models/surface_generation_models.dart';
import '../../cad_kernel/io/kernel_io_models.dart';

class SurfaceGenerationRepository {
  const SurfaceGenerationRepository(this.projectDirectory);
  final Directory projectDirectory;
  Directory get generated =>
      Directory(path.join(projectDirectory.path, 'GeneratedSurfaces'));
  Directory get history =>
      Directory(path.join(projectDirectory.path, 'SurfaceHistory'));
  Directory get registry =>
      Directory(path.join(projectDirectory.path, 'SurfaceRegistry'));
  Directory get diagnostics =>
      Directory(path.join(projectDirectory.path, 'SurfaceDiagnostics'));
  Future<void> initialize() async {
    for (final d in [generated, history, registry, diagnostics]) {
      await d.create(recursive: true);
    }
  }

  Future<void> save(
    GeneratedSurface surface,
    GeneratedSurfaceGraph graph,
  ) async {
    await initialize();
    await File(
      path.join(generated.path, '${surface.surfaceId}.json'),
    ).writeAsString(jsonEncode(surface.toJson()), flush: true);
    await File(path.join(registry.path, 'registry.jsonl')).writeAsString(
      '${jsonEncode(surface.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
    await File(path.join(history.path, 'events.jsonl')).writeAsString(
      '${jsonEncode({'action': 'generate', 'surfaceId': surface.surfaceId, 'timestamp': DateTime.now().toIso8601String()})}\n',
      mode: FileMode.append,
      flush: true,
    );
    await File(
      path.join(registry.path, 'surface_graph.json'),
    ).writeAsString(jsonEncode(graph.toJson()), flush: true);
    await saveDiagnostics(surface.surfaceId, surface.diagnostics);
  }

  Future<void> saveAttempt(
    String candidateId,
    SurfaceGenerationStatus status,
    List<GeometryDiagnostic> values,
  ) async {
    await initialize();
    await File(path.join(history.path, 'events.jsonl')).writeAsString(
      '${jsonEncode({'action': 'attempt', 'candidateId': candidateId, 'status': status.name, 'timestamp': DateTime.now().toIso8601String()})}\n',
      mode: FileMode.append,
      flush: true,
    );
    await saveDiagnostics(candidateId, values);
  }

  Future<void> saveDiagnostics(String id, List<GeometryDiagnostic> values) =>
      File(path.join(diagnostics.path, '$id.json')).writeAsString(
        jsonEncode(
          values
              .map(
                (e) => {
                  'code': e.code,
                  'message': e.message,
                  'severity': e.severity,
                  'shapeId': e.shapeId,
                  'metadata': e.metadata,
                },
              )
              .toList(),
        ),
        flush: true,
      );
  Future<void> delete(String id) async {
    final file = File(path.join(generated.path, '$id.json'));
    if (await file.exists()) await file.delete();
  }
}
