import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../analytics/mesh_analytics.dart';
import '../history/mesh_history.dart';
import '../integration/mesh_integration.dart';
import '../models/mesh_models.dart';
import '../repository/mesh_repository.dart';
import '../validation/mesh_validation.dart';

class MeshEngine {
  MeshEngine({
    required this.kernel,
    required this.repository,
    this.integration,
  });
  final GeometryKernelAPI kernel;
  final MeshRepository repository;
  final MeshIntegration? integration;
  final MeshAnalytics analytics = MeshAnalytics();
  final MeshHistory history = MeshHistory();
  final MeshValidation validation = const MeshValidation();
  final Map<String, List<MeshDiagnostic>> diagnostics = {};
  Future<MeshImportResult> importStl(
    String path, {
    required String projectId,
    String units = 'mm',
    KernelImportFormat format = KernelImportFormat.autoDetect,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('STL file is unavailable: $path');
    }
    final size = await file.length();
    if (size == 0) throw StateError('STL file is empty: $path');
    if (kernel is! MeshGeometryKernelAPI) {
      throw StateError(
        'Active GeometryKernelAPI does not support STL mesh import',
      );
    }
    final total = Stopwatch()..start(), kernelWatch = Stopwatch()..start();
    final handle = await (kernel as MeshGeometryKernelAPI).importStl(
      path,
      projectId: projectId,
      format: format,
    );
    kernelWatch.stop();
    final mesh = MeshEntity(
      id: handle.persistentId,
      name: file.uri.pathSegments.last,
      sourceFile: file.absolute.path,
      checksum: await _checksum(file),
      fileSize: size,
      kernelHandle: handle,
      units: units,
      orientation: 'source',
      importDate: DateTime.now().toUtc(),
      importTime: total.elapsed,
      kernelTime: kernelWatch.elapsed,
      repositoryTime: Duration.zero,
      health: MeshHealth.healthy,
      validationStatus: 'validated',
    );
    final issues = validation.validate(mesh);
    mesh.health = issues.any((e) => e.severity == 'error')
        ? MeshHealth.invalid
        : issues.isEmpty
        ? MeshHealth.healthy
        : MeshHealth.warning;
    repository.register(mesh);
    diagnostics[mesh.id] = issues;
    history.add(mesh.id, 'Import STL');
    analytics.imports++;
    analytics.repositoryUpdates++;
    analytics.diagnostics++;
    analytics.validations++;
    analytics.metadataGenerations++;
    analytics.vertices += mesh.vertexCount;
    analytics.triangles += mesh.triangleCount;
    analytics.memoryBytes += size;
    analytics.importTime += total.elapsed;
    integration?.onMeshImported(mesh);
    return MeshImportResult(mesh, List.unmodifiable(issues));
  }

  Future<MeshImportResult> reload(
    String id, {
    KernelImportFormat format = KernelImportFormat.autoDetect,
  }) async {
    final previous =
        repository.find(id) ?? (throw StateError('Unknown mesh: $id'));
    await (kernel as MeshGeometryKernelAPI).closeMesh(previous.kernelHandle);
    repository.remove(id);
    final result = await importStl(
      previous.sourceFile,
      projectId: 'project',
      units: previous.units,
      format: format,
    );
    analytics.reloads++;
    history.add(result.mesh.id, 'Reload STL');
    return result;
  }

  Future<void> close(String id) async {
    final mesh = repository.find(id) ?? (throw StateError('Unknown mesh: $id'));
    await (kernel as MeshGeometryKernelAPI).closeMesh(mesh.kernelHandle);
    mesh.state = MeshState.closed;
    history.add(id, 'Close Mesh');
    integration?.onMeshClosed(mesh);
  }

  Future<void> persist() => repository.persist(
    analytics: analytics,
    history: history,
    diagnostics: diagnostics,
  );
  Future<String> _checksum(File file) async {
    var hash = 0xcbf29ce484222325;
    await for (final bytes in file.openRead()) {
      for (final byte in bytes) {
        hash ^= byte;
        hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
      }
    }
    return 'fnv1a64:${hash.toRadixString(16).padLeft(16, '0')}';
  }
}
