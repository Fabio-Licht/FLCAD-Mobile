import '../../core/cad_document/entity_placement.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';

/// Projects detached display coordinates; never transforms a native owner or asset.
Map<String, dynamic> projectManagedPlacement(
  Map<String, dynamic> local,
  EntityPlacement? placement,
) {
  if (placement == null || placement.operations.isEmpty) return local;
  final matrix = placement.matrix;
  List<double> triples(Object? raw, {bool normal = false}) {
    if (raw is! List ||
        raw.length % 3 != 0 ||
        raw.any((v) => v is! num || !v.isFinite)) {
      throw const FormatException('Invalid placement presentation coordinates');
    }
    final result = <double>[];
    for (var i = 0; i < raw.length; i += 3) {
      final p = matrix.transformPoint(
        Vector3(
          (raw[i] as num).toDouble(),
          (raw[i + 1] as num).toDouble(),
          (raw[i + 2] as num).toDouble(),
        ),
      );
      // For a validated rigid matrix inverse-transpose is the rotation itself.
      final m = matrix.values;
      final value = normal
          ? Vector3(
              m[0] * (raw[i] as num) +
                  m[1] * (raw[i + 1] as num) +
                  m[2] * (raw[i + 2] as num),
              m[4] * (raw[i] as num) +
                  m[5] * (raw[i + 1] as num) +
                  m[6] * (raw[i + 2] as num),
              m[8] * (raw[i] as num) +
                  m[9] * (raw[i + 1] as num) +
                  m[10] * (raw[i + 2] as num),
            ).normalized
          : p;
      if (![value.x, value.y, value.z].every((v) => v.isFinite)) {
        throw const FormatException('Placement presentation overflow');
      }
      result.addAll([value.x, value.y, value.z]);
    }
    return List.unmodifiable(result);
  }

  List<double> bounds(Object? raw) {
    if (raw is! List ||
        raw.length != 6 ||
        raw.any((v) => v is! num || !v.isFinite)) {
      throw const FormatException('Invalid placement presentation bounds');
    }
    final corners = triples([
      for (final x in [raw[0], raw[3]])
        for (final y in [raw[1], raw[4]])
          for (final z in [raw[2], raw[5]]) ...[x, y, z],
    ]);
    return List.unmodifiable([
      for (var axis = 0; axis < 3; axis++)
        [
          for (var i = axis; i < corners.length; i += 3) corners[i],
        ].reduce((a, b) => a < b ? a : b),
      for (var axis = 0; axis < 3; axis++)
        [
          for (var i = axis; i < corners.length; i += 3) corners[i],
        ].reduce((a, b) => a > b ? a : b),
    ]);
  }

  List<List<double>> edges(Object? raw) {
    if (raw is! List) {
      throw const FormatException('Invalid placement CAD edges');
    }
    return List.unmodifiable(raw.map((edge) => triples(edge)));
  }

  Map<String, dynamic> project(Map<String, dynamic> geometry) => {
    ...geometry,
    if (geometry['nodes'] != null) 'nodes': triples(geometry['nodes']),
    if (geometry['normals'] != null)
      'normals': triples(geometry['normals'], normal: true),
    if (geometry['bounds'] != null) 'bounds': bounds(geometry['bounds']),
    if (geometry['topologicalEdges'] != null)
      'topologicalEdges': edges(geometry['topologicalEdges']),
  };
  return {
    ...project(local),
    if (local['brepPresentation'] is Map)
      'brepPresentation': project(
        Map<String, dynamic>.from(local['brepPresentation'] as Map),
      ),
  };
}
