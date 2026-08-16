import '../../core/cad_document/cad_document.dart';
import '../cad_viewport/scene/cad_scene_graph.dart';
import '../cad_viewport/rendering/kernel_display_mesh_pipeline.dart';

class CadDocumentSceneProjection {
  CadDocumentSceneProjection(this.scene);
  final CadSceneGraph scene;
  final Map<String, CadSceneEntity> _transient = {};

  void select(Set<String> ids) => scene.select(ids);

  void upsertTransient(CadSceneEntity entity) {
    _transient[entity.id] = entity;
    scene.upsert(entity);
  }

  void removeTransient(String id) {
    _transient.remove(id);
    scene.remove(id);
  }

  void clearTransient() {
    final ids = _transient.keys.toList();
    _transient.clear();
    for (final id in ids) {
      scene.remove(id);
    }
  }

  Future<void> synchronize(
    CadDocument document, {
    KernelDisplayMeshPipeline? displayMeshes,
  }) async {
    final meshes = displayMeshes;
    final expected = {...document.entities.keys, ..._transient.keys};
    for (final entity in scene.entities.toList()) {
      if (!expected.contains(entity.id)) scene.remove(entity.id);
    }
    for (final entity in document.entities.values) {
      final geometry = entity.data['sceneGeometry'];
      if (geometry is! Map) continue;
      scene.upsert(
        CadSceneEntity(
          id: entity.id,
          kind: _kind(entity),
          geometry: Map<String, dynamic>.from(geometry),
          visible: entity.data['sceneVisible'] as bool? ?? true,
          transparent: entity.data['sceneTransparent'] as bool? ?? false,
        ),
      );
      if (entity.shape != null && meshes != null && meshes.supported) {
        await meshes.upsert(entityId: entity.id, shape: entity.shape!);
      }
    }
    for (final entity in _transient.values) {
      scene.upsert(entity);
    }
  }

  CadSceneEntityKind _kind(CadDocumentEntity entity) {
    final value = entity.data['sceneKind'] as String?;
    if (value != null) {
      return CadSceneEntityKind.values.byName(value);
    }
    return switch (entity.kind) {
      CadDocumentEntityKind.import when entity.mesh != null =>
        CadSceneEntityKind.mesh,
      CadDocumentEntityKind.import => CadSceneEntityKind.solid,
      CadDocumentEntityKind.reference => CadSceneEntityKind.gizmo,
      CadDocumentEntityKind.sketch => CadSceneEntityKind.sketch,
      CadDocumentEntityKind.constraint => CadSceneEntityKind.gizmo,
      CadDocumentEntityKind.surface => CadSceneEntityKind.surface,
    };
  }
}
