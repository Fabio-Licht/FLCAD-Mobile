import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../core/cad_kernel/api/geometry_kernel_api.dart';
import '../../../core/cad_kernel/io/kernel_io_models.dart';
import '../../../core/cad_kernel/models/kernel_models.dart';
import '../scene/cad_scene_graph.dart';

class KernelDisplayMesh {
  const KernelDisplayMesh({
    required this.source,
    required this.geometry,
    required this.bounds,
    required this.payloadPath,
    required this.deflection,
  });

  final ShapeHandle source;
  final KernelMeshGeometry geometry;
  final KernelBounds bounds;
  final String payloadPath;
  final double deflection;
}

/// Builds display-only meshes through OCCT's official meshing operation.
class KernelDisplayMeshPipeline {
  const KernelDisplayMeshPipeline({
    required this.kernel,
    required this.projectId,
    required this.projectDirectory,
    required this.scene,
  });

  final GeometryKernelAPI kernel;
  final String projectId;
  final Directory projectDirectory;
  final CadSceneGraph scene;
  bool get supported =>
      kernel is InterchangeGeometryKernelAPI && kernel is MeshGeometryKernelAPI;

  Future<KernelDisplayMesh> upsert({
    required String entityId,
    required ShapeHandle shape,
    double deflection = 0.1,
  }) async {
    final active = kernel;
    if (!supported) {
      throw StateError(
        'The active kernel does not expose OCCT display meshing.',
      );
    }
    final interchange = active as InterchangeGeometryKernelAPI;
    final meshKernel = active as MeshGeometryKernelAPI;
    var effectiveShape = shape;
    final payloadName = shape.persistentId.replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '_',
    );
    if (active is PersistentGeometryKernelAPI) {
      final persistence = kernel as PersistentGeometryKernelAPI;
      final nativeDirectory = Directory(
        path.join(projectDirectory.path, 'NativeShapes'),
      );
      await nativeDirectory.create(recursive: true);
      final nativePath = path.join(nativeDirectory.path, '$payloadName.brep');
      try {
        await persistence.persistShape(shape, nativePath);
      } on StateError {
        if (!await File(nativePath).exists()) rethrow;
        effectiveShape = await persistence.restoreShape(
          nativePath,
          persistentId: shape.persistentId,
        );
      }
    }
    final directory = Directory(
      path.join(projectDirectory.path, 'DisplayMeshes'),
    );
    await directory.create(recursive: true);
    final payload = path.join(directory.path, '$payloadName.stl');
    final result = await interchange.mesh(
      effectiveShape,
      outputPath: payload,
      deflection: deflection,
    );
    final mesh = await meshKernel.importStl(
      result.payloadPath,
      projectId: projectId,
      format: KernelImportFormat.stl,
    );
    try {
      final geometry = await meshKernel.inspectMesh(mesh);
      final display = KernelDisplayMesh(
        source: effectiveShape,
        geometry: geometry,
        bounds: mesh.bounds,
        payloadPath: result.payloadPath,
        deflection: deflection,
      );
      final existing = scene.find(entityId);
      scene.upsert(
        CadSceneEntity(
          id: entityId,
          kind: existing?.kind ?? CadSceneEntityKind.surface,
          visible: existing?.visible ?? true,
          selected: existing?.selected ?? false,
          transparent: existing?.transparent ?? false,
          geometry: {
            ...?existing?.geometry,
            'handle': effectiveShape.toJson(),
            'nodes': geometry.nodes,
            'triangles': geometry.triangles,
            'bounds': mesh.bounds.toJson(),
            'displayMeshPath': result.payloadPath,
            'displayDeflection': deflection,
          },
        ),
      );
      return display;
    } finally {
      await meshKernel.closeMesh(mesh);
    }
  }
}
