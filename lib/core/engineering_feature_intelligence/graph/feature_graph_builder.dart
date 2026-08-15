import '../../primitive_intelligence/models/primitive_intelligence_models.dart';
import '../models/engineering_feature_models.dart';

class FeatureGraphBuilder {
  const FeatureGraphBuilder();
  FeatureGraph build({
    required String id,
    required PrimitiveHypothesis primitive,
    required PrimitiveIntelligenceSession source,
  }) {
    final nodes = <FeatureGraphNode>[
      FeatureGraphNode(
        id: 'primitive:${primitive.primitive.id}',
        kind: primitive.primitive.type.name,
        referenceId: primitive.primitive.id,
      ),
      for (final adjacent in primitive.primitive.adjacentIds)
        FeatureGraphNode(
          id: 'primitive:$adjacent',
          kind: 'adjacentPrimitive',
          referenceId: adjacent,
        ),
      if (primitive.axis != null)
        FeatureGraphNode(
          id: 'axis:${primitive.primitive.id}',
          kind: 'axis',
          referenceId: primitive.primitive.id,
        ),
      if (primitive.symmetry != null)
        FeatureGraphNode(
          id: 'symmetry:${primitive.primitive.id}',
          kind: 'symmetry',
          referenceId: primitive.symmetry!.kind.name,
        ),
      for (final pattern in source.patterns.where(
        (p) => p.memberIds.contains(primitive.primitive.id),
      ))
        FeatureGraphNode(
          id: 'pattern:${pattern.kind.name}',
          kind: 'pattern',
          referenceId: pattern.kind.name,
        ),
      for (final kind in const ['boundaries', 'patches', 'axes', 'points'])
        for (final reference
            in (source.context.values[kind] as List<dynamic>? ?? const []))
          FeatureGraphNode(
            id: '$kind:$reference',
            kind: kind,
            referenceId: reference.toString(),
          ),
      for (final relation in const [
        'parallelism',
        'perpendicularity',
        'alignment',
      ])
        if ((primitive.primitive.measures[relation] ?? 0) > 0)
          FeatureGraphNode(
            id: 'relationship:$relation',
            kind: relation,
            referenceId: primitive.primitive.id,
          ),
    ];
    final unique = <String, FeatureGraphNode>{
      for (final node in nodes) node.id: node,
    };
    final root = 'primitive:${primitive.primitive.id}';
    final edges = <FeatureGraphEdge>[];
    for (final node in unique.values.where((e) => e.id != root)) {
      final relation = node.kind == 'axis'
          ? FeatureRelationshipType.coaxiality
          : node.kind == 'pattern'
          ? FeatureRelationshipType.sequence
          : node.kind == 'symmetry'
          ? FeatureRelationshipType.alignment
          : node.kind == 'parallelism'
          ? FeatureRelationshipType.parallelism
          : node.kind == 'perpendicularity'
          ? FeatureRelationshipType.perpendicularity
          : node.kind == 'alignment'
          ? FeatureRelationshipType.alignment
          : FeatureRelationshipType.dependency;
      edges.add(
        FeatureGraphEdge(
          from: root,
          to: node.id,
          relationship: relation,
          score: primitive.scores.confidence,
        ),
      );
    }
    return FeatureGraph(id: id, nodes: unique.values, edges: edges);
  }
}
