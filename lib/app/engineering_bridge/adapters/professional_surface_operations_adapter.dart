import '../../../core/cad_kernel/io/kernel_io_models.dart';
import '../../../core/cad_kernel/models/kernel_models.dart';
import '../../../core/feature_lifecycle/feature_update_solver.dart';
import '../../../core/parametric_solver/parametric_solver.dart';
import '../../../core/surface_generation/api/surface_generation_api.dart';
import '../../../core/surface_generation/models/surface_generation_models.dart';
import '../../../core/surface_generation/models/surface_topology.dart';

class SurfaceHealthSnapshot {
  const SurfaceHealthSnapshot({
    required this.valid,
    required this.kernelOk,
    required this.topologyOk,
    required this.boundariesOk,
    required this.readyForLoft,
  });
  final bool valid, kernelOk, topologyOk, boundariesOk, readyForLoft;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'kernelOk': kernelOk,
    'topologyOk': topologyOk,
    'boundariesOk': boundariesOk,
    'readyForLoft': readyForLoft,
  };
}

/// Translates professional Surface operations to the domain-neutral Solver
/// contract. GeneratedSurface remains a passive Feature data object.
class ProfessionalSurfaceOperationsAdapter {
  const ProfessionalSurfaceOperationsAdapter({
    this.updates = const FeatureUpdateSolver(),
  });
  final FeatureUpdateSolver updates;

  SurfaceHealthSnapshot health(GeneratedSurface surface) {
    final raw = surface.parameters['topology'];
    final topology = raw is Map
        ? SurfaceTopology.fromJson(raw.cast<String, dynamic>())
        : const SurfaceTopology(
            loops: [],
            edges: [],
            vertices: [],
            area: 0,
            perimeter: 0,
          );
    final topologyOk = topology.loops.isNotEmpty && topology.edges.isNotEmpty;
    final boundariesOk = topology.loops.every(
      (loop) =>
          loop.edgeIds.isNotEmpty &&
          loop.edgeIds.every(
            (id) => topology.edges.any((edge) => edge.id == id),
          ),
    );
    return SurfaceHealthSnapshot(
      valid: surface.valid,
      kernelOk: surface.handle.kernelId.isNotEmpty,
      topologyOk: topologyOk,
      boundariesOk: boundariesOk,
      readyForLoft:
          surface.valid &&
          topologyOk &&
          boundariesOk &&
          !surface.diagnostics.any(
            (diagnostic) => diagnostic.severity.toLowerCase() == 'error',
          ),
    );
  }

  Future<GeneratedSurface> reverseNormal({
    required GeneratedSurface source,
    required SurfaceGenerationApi generation,
    required SurfaceOperationKernelAPI kernel,
  }) => updates.update(
    request: _request(source.surfaceId, 'normalDirection', -1),
    apply: (_) async {
      final result = await kernel.executeSurfaceOperation(
        source.handle,
        'reverseNormal',
        const {},
        projectId: source.projectId,
      );
      if (!result.supported || result.result == null) {
        throw StateError(result.diagnostic);
      }
      final normal = (source.parameters['normal'] as List).cast<num>();
      final updated = _copy(
        source,
        handle: result.result,
        revision: source.revision + 1,
        parameters: {
          ...source.parameters,
          'normal': normal.map((value) => -value.toDouble()).toList(),
          'normalReversed':
              !(source.parameters['normalReversed'] as bool? ?? false),
          'lastOperation': 'reverseNormal',
        },
      );
      await generation.engine.restore(updated);
      return updated;
    },
  );

  Future<GeneratedSurface> offset({
    required String featureId,
    required GeneratedSurface source,
    required double distance,
    required SurfaceGenerationApi generation,
    required SurfaceOperationKernelAPI kernel,
    GeneratedSurface? existing,
  }) => updates.update(
    request: _request(featureId, 'offsetDistance', distance),
    apply: (_) async {
      final result = await kernel.executeSurfaceOperation(
        source.handle,
        'offsetSurface',
        {'distance': distance},
        projectId: source.projectId,
      );
      if (!result.supported || result.result == null) {
        throw StateError(result.diagnostic);
      }
      final normal = (source.parameters['normal'] as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList();
      List<double> translate(List<dynamic> point) => [
        (point[0] as num).toDouble() + normal[0] * distance,
        (point[1] as num).toDouble() + normal[1] * distance,
        (point[2] as num).toDouble() + normal[2] * distance,
      ];
      final nodes = (source.parameters['displayNodes'] as List).cast<num>();
      final translatedNodes = <double>[];
      for (var index = 0; index + 2 < nodes.length; index += 3) {
        translatedNodes.addAll(
          translate([nodes[index], nodes[index + 1], nodes[index + 2]]),
        );
      }
      final sourceTopology = SurfaceTopology.fromJson(
        (source.parameters['topology'] as Map).cast<String, dynamic>(),
      );
      final usedEdges = generation.engine.registry.surfaces
          .expand(_topologyEdges)
          .map((edge) => edge.id)
          .toSet();
      final usedVertices = generation.engine.registry.surfaces
          .expand(_topologyVertices)
          .map((vertex) => vertex.id)
          .toSet();
      String allocate(String prefix, Set<String> used) {
        var number = 1;
        while (used.contains('$prefix${number.toString().padLeft(3, '0')}')) {
          number++;
        }
        final id = '$prefix${number.toString().padLeft(3, '0')}';
        used.add(id);
        return id;
      }

      final existingTopology = existing?.parameters['topology'] is Map
          ? SurfaceTopology.fromJson(
              (existing!.parameters['topology'] as Map).cast<String, dynamic>(),
            )
          : null;
      final vertexMap = <String, String>{};
      var vertexIndex = 0;
      final vertices = [
        for (final vertex in sourceTopology.vertices)
          SurfaceVertex(
            id: vertexMap[vertex.id] =
                existingTopology?.vertices.elementAtOrNull(vertexIndex++)?.id ??
                allocate('Vertex', usedVertices),
            sourceKeys: vertex.sourceKeys,
            position: translate(vertex.position),
          ),
      ];
      final edgeMap = <String, String>{};
      var edgeIndex = 0;
      final edges = [
        for (final edge in sourceTopology.edges)
          SurfaceEdge(
            id: edgeMap[edge.id] =
                existingTopology?.edges.elementAtOrNull(edgeIndex++)?.id ??
                allocate('Edge', usedEdges),
            sourceEntityId: edge.sourceEntityId,
            vertexIds: edge.vertexIds.map((id) => vertexMap[id]!).toList(),
            points: edge.points.map(translate).toList(),
          ),
      ];
      final topology = SurfaceTopology(
        loops: [
          for (final loop in sourceTopology.loops)
            SurfaceLoop(
              id: loop.outer ? 'Outer Loop' : loop.id,
              outer: loop.outer,
              edgeIds: loop.edgeIds.map((id) => edgeMap[id]!).toList(),
            ),
        ],
        edges: edges,
        vertices: vertices,
        area: sourceTopology.area,
        perimeter: sourceTopology.perimeter,
      );
      final created = _copy(
        source,
        surfaceId: featureId,
        featureId: featureId,
        handle: result.result,
        revision: existing == null ? 1 : existing.revision + 1,
        parameters: {
          ...source.parameters,
          'origin': translate(
            (source.parameters['origin'] as List).cast<dynamic>(),
          ),
          'displayNodes': translatedNodes,
          'topology': topology.toJson(),
          'operation': 'offset',
          'sourceSurfaceId': source.surfaceId,
          'offsetDistance': distance,
          'lastOperation': 'offset',
        },
      );
      await generation.engine.restore(created);
      return created;
    },
  );

  Future<List<GeneratedSurface>> setJoined({
    required GeneratedSurface first,
    required GeneratedSurface second,
    required bool joined,
    required SurfaceGenerationApi generation,
  }) => updates.update(
    request: ParametricSolveRequest(
      first: '${first.surfaceId}:topology',
      second: '${second.surfaceId}:topology',
      degreesOfFreedom: [
        ParametricDegreeOfFreedom('${first.surfaceId}:topology', fixed: true),
        ParametricDegreeOfFreedom('${second.surfaceId}:topology'),
      ],
      anchors: {'${first.surfaceId}:topology'},
    ),
    apply: (_) async {
      GeneratedSurface update(GeneratedSurface source, String peer) {
        final ids = (source.parameters['joinedSurfaceIds'] as List? ?? const [])
            .whereType<String>()
            .toSet();
        joined ? ids.add(peer) : ids.remove(peer);
        return _copy(
          source,
          revision: source.revision + 1,
          parameters: {
            ...source.parameters,
            'joinedSurfaceIds': ids.toList()..sort(),
            'lastOperation': joined ? 'join' : 'unjoin',
          },
        );
      }

      final values = [
        update(first, second.surfaceId),
        update(second, first.surfaceId),
      ];
      for (final value in values) {
        await generation.engine.restore(value);
      }
      return values;
    },
  );

  ParametricSolveRequest _request(String id, String parameter, double value) =>
      ParametricSolveRequest(
        first: '$id:source',
        second: '$id:result',
        degreesOfFreedom: [
          ParametricDegreeOfFreedom('$id:source', fixed: true),
          ParametricDegreeOfFreedom(
            '$id:result',
            parameterIds: {'$id:$parameter'},
          ),
        ],
        parameters: [ParametricParameter('$id:$parameter', value)],
        anchors: {'$id:source'},
      );

  Iterable<SurfaceEdge> _topologyEdges(GeneratedSurface surface) {
    final raw = surface.parameters['topology'];
    return raw is Map
        ? SurfaceTopology.fromJson(raw.cast<String, dynamic>()).edges
        : const [];
  }

  Iterable<SurfaceVertex> _topologyVertices(GeneratedSurface surface) {
    final raw = surface.parameters['topology'];
    return raw is Map
        ? SurfaceTopology.fromJson(raw.cast<String, dynamic>()).vertices
        : const [];
  }

  GeneratedSurface _copy(
    GeneratedSurface source, {
    String? surfaceId,
    String? featureId,
    ShapeHandle? handle,
    int? revision,
    Map<String, dynamic>? parameters,
  }) => GeneratedSurface(
    surfaceId: surfaceId ?? source.surfaceId,
    projectId: source.projectId,
    kind: source.kind,
    origin: source.origin,
    regionIds: source.regionIds,
    evidenceIds: source.evidenceIds,
    featureId: featureId ?? source.featureId,
    handle: handle ?? source.handle,
    revision: revision ?? source.revision,
    timestamp: DateTime.now().toUtc(),
    parameters: parameters ?? source.parameters,
    continuity: source.continuity,
    valid: source.valid,
    confidence: source.confidence,
    diagnostics: source.diagnostics,
  );
}
