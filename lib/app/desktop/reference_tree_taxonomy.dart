import '../../core/cad_document/cad_document.dart';
import '../../core/cad_document/managed_cad_reference.dart';
import '../../core/cad_document/plane_axis_intersection_point.dart';
import '../../core/cad_document/alignment_coordinate_system.dart';
import '../runtime/world_coordinate_system.dart';

/// UI-only taxonomy for the Explorer. It deliberately projects existing
/// durable identities and never moves an entity between document models.
enum ReferenceTreeGroup {
  coordinateSystem('Sistema de coordenadas'),
  points('Pontos'),
  axes('Eixos'),
  planes('Planos'),
  curves('Curvas'),
  other('Outros');

  const ReferenceTreeGroup(this.label);
  final String label;
}

abstract final class ReferenceTreeTaxonomy {
  static const orderedGroups = ReferenceTreeGroup.values;

  static bool isProjectedReference(CadDocumentEntity entity) =>
      groupFor(entity) != null;

  static ReferenceTreeGroup? groupFor(CadDocumentEntity entity) {
    if (entity.kind == CadDocumentEntityKind.collection ||
        entity.data['deleted'] == true) {
      return null;
    }
    if (WorldCoordinateSystem.isProtected(entity)) {
      return ReferenceTreeGroup.coordinateSystem;
    }
    final inReferenceCollection =
        entity.data['collectionId'] == 'collection:references';
    if (!inReferenceCollection &&
        entity.kind != CadDocumentEntityKind.reference) {
      return null;
    }
    return _semanticType(entity);
  }

  static Map<ReferenceTreeGroup, List<CadDocumentEntity>> grouped(
    Iterable<CadDocumentEntity> entities,
  ) {
    final result = {
      for (final group in orderedGroups) group: <CadDocumentEntity>[],
    };
    for (final entity in entities) {
      final group = groupFor(entity);
      if (group != null) result[group]!.add(entity);
    }
    result[ReferenceTreeGroup.coordinateSystem]!.sort(_systemOrder);
    return result;
  }

  static String originLabel(CadDocumentEntity entity) {
    if (WorldCoordinateSystem.isProtected(entity)) return 'Sistema padrão';
    if (entity.data[ManagedCadReference.dataKey] is Map) {
      return 'Face STEP/BREP — topologia exata';
    }
    if (entity.data[PlaneAxisIntersectionPoint.dataKey] is Map) {
      return 'Plano + Eixo — snapshot';
    }
    if (entity.data[AlignmentCoordinateSystem.dataKey] is Map) {
      final reference = AlignmentCoordinateSystem.fromJson(
        Map<String, dynamic>.from(
          entity.data[AlignmentCoordinateSystem.dataKey] as Map,
        ),
      );
      return switch (reference.originKind) {
        AlignmentCoordinateSystemOriginKind.referencePoint =>
          'Plano + Eixo + Ponto — snapshot',
        AlignmentCoordinateSystemOriginKind.manual =>
          'Plano + Eixo + Origem manual — snapshot',
        AlignmentCoordinateSystemOriginKind.viewport =>
          'Plano + Eixo + Origem da viewport — snapshot',
      };
    }
    final construction = entity.data['constructionEntity'];
    if (construction is Map) return 'Manual';
    final reference = entity.data['reference'];
    if (reference is Map) {
      final recipe = reference['recipe'];
      final parameters = recipe is Map ? recipe['parameters'] : null;
      final method = parameters is Map ? parameters['method'] : null;
      final name = reference['name'];
      if (method == 'region' ||
          method == 'centroid' ||
          (parameters is Map && parameters['tolerance'] is num) ||
          (name is String && name.startsWith('Recognized '))) {
        return 'Região STL — ajuste de malha';
      }
      final sourceIds = recipe is Map ? recipe['sourceIds'] : null;
      if (sourceIds is List && sourceIds.isNotEmpty) {
        return 'Referência derivada';
      }
    }
    return 'Manual';
  }

  static ReferenceTreeGroup _semanticType(CadDocumentEntity entity) {
    final managed = entity.data[ManagedCadReference.dataKey];
    if (managed is Map) {
      final kind = managed['kind'];
      return kind == ManagedCadReferenceKind.cylindricalAxis.name
          ? ReferenceTreeGroup.axes
          : ReferenceTreeGroup.planes;
    }
    final reference = entity.data['reference'];
    if (reference is Map) {
      final geometry = reference['geometry'];
      if (geometry is Map) return _sceneType(geometry['type']);
    }
    final construction = entity.data['constructionEntity'];
    if (construction is Map) return _constructionType(construction['type']);
    return _sceneType(entity.data['sceneKind']);
  }

  static ReferenceTreeGroup _constructionType(Object? type) => switch (type) {
    'point' => ReferenceTreeGroup.points,
    'plane' => ReferenceTreeGroup.planes,
    'vector' => ReferenceTreeGroup.axes,
    'curve' => ReferenceTreeGroup.curves,
    _ => ReferenceTreeGroup.other,
  };

  static ReferenceTreeGroup _sceneType(Object? type) => switch (type) {
    'coordinateSystem' => ReferenceTreeGroup.coordinateSystem,
    'point' => ReferenceTreeGroup.points,
    'axis' => ReferenceTreeGroup.axes,
    'plane' => ReferenceTreeGroup.planes,
    'curve' => ReferenceTreeGroup.curves,
    _ => ReferenceTreeGroup.other,
  };

  static int _systemOrder(CadDocumentEntity a, CadDocumentEntity b) =>
      _systemRank(a).compareTo(_systemRank(b));

  static int _systemRank(CadDocumentEntity entity) {
    for (final entry in const [
      ('origin', 0),
      ('x-axis', 1),
      ('y-axis', 2),
      ('z-axis', 3),
      ('xy-plane', 4),
      ('xz-plane', 5),
      ('yz-plane', 6),
      ('coordinate-system', -1),
    ]) {
      if (entity.id.endsWith(':${entry.$1}')) return entry.$2;
    }
    return 1000;
  }
}
