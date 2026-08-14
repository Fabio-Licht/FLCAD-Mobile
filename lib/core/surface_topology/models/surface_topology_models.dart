import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_fitting/models/surface_fitting_models.dart';

enum BoundaryType { natural, open, closed, internal, external }

enum TopologyHealth { healthy, warning, invalid }

enum LoopType { outer, inner, closed, open, micro, invalid }

class BoundaryEntity {
  const BoundaryEntity({
    required this.id,
    required this.length,
    required this.type,
    required this.connectedSurfaceIds,
    required this.confidence,
    required this.health,
    required this.nativeIndex,
  });
  final String id;
  final double length, confidence;
  final BoundaryType type;
  final List<String> connectedSurfaceIds;
  final TopologyHealth health;
  final int nativeIndex;
  Map<String, dynamic> toJson() => {
    'id': id,
    'length': length,
    'type': type.name,
    'connectedSurfaces': connectedSurfaceIds,
    'confidence': confidence,
    'health': health.name,
    'nativeIndex': nativeIndex,
  };
}

class LoopEntity {
  const LoopEntity({
    required this.id,
    required this.surfaceId,
    required this.boundaryIds,
    required this.type,
    required this.closed,
    required this.health,
  });
  final String id, surfaceId;
  final List<String> boundaryIds;
  final LoopType type;
  final bool closed;
  final TopologyHealth health;
  Map<String, dynamic> toJson() => {
    'id': id,
    'surfaceId': surfaceId,
    'boundaries': boundaryIds,
    'type': type.name,
    'closed': closed,
    'health': health.name,
  };
}

class IntersectionEntity {
  const IntersectionEntity({
    required this.id,
    required this.firstSurfaceId,
    required this.secondSurfaceId,
    required this.type,
    required this.length,
    required this.edgeCount,
    required this.quality,
    this.handle,
  });
  final String id, firstSurfaceId, secondSurfaceId, type;
  final double length, quality;
  final int edgeCount;
  final ShapeHandle? handle;
  Map<String, dynamic> toJson() => {
    'id': id,
    'firstSurface': firstSurfaceId,
    'secondSurface': secondSurfaceId,
    'type': type,
    'length': length,
    'edgeCount': edgeCount,
    'quality': quality,
    'handle': handle?.toJson(),
    'native': handle != null,
  };
}

class PatchEntity {
  const PatchEntity({
    required this.id,
    required this.surface,
    required this.boundaryIds,
    required this.loopIds,
    required this.adjacentPatchIds,
    required this.intersectionIds,
    required this.recognitionRegionId,
    required this.confidence,
    required this.health,
    required this.status,
  });
  final String id, recognitionRegionId, status;
  final SurfaceEntity surface;
  final List<String> boundaryIds, loopIds, adjacentPatchIds, intersectionIds;
  final double confidence;
  final TopologyHealth health;
  Map<String, dynamic> toJson() => {
    'id': id,
    'surfaceHandle': surface.handle?.toJson(),
    'surfaceId': surface.id,
    'boundaries': boundaryIds,
    'loops': loopIds,
    'adjacency': adjacentPatchIds,
    'intersections': intersectionIds,
    'recognitionRegion': recognitionRegionId,
    'confidence': confidence,
    'health': health.name,
    'status': status,
    'createsSolid': false,
  };
}

class SurfaceTopologyGraph {
  const SurfaceTopologyGraph(this.nodes, this.edges);
  final Map<String, String> nodes;
  final Map<String, Set<String>> edges;
  Map<String, dynamic> toJson() => {
    'nodes': nodes,
    'edges': edges.map((k, v) => MapEntry(k, v.toList()..sort())),
  };
}

class SurfaceTopologyAnalytics {
  const SurfaceTopologyAnalytics({
    required this.elapsed,
    required this.patchCount,
    required this.boundaryCount,
    required this.loopCount,
    required this.intersectionCount,
    required this.adjacencyCount,
    required this.validCount,
    required this.invalidCount,
    required this.averageConfidence,
  });
  final Duration elapsed;
  final int patchCount,
      boundaryCount,
      loopCount,
      intersectionCount,
      adjacencyCount,
      validCount,
      invalidCount;
  final double averageConfidence;
  Map<String, dynamic> toJson() => {
    'patches': patchCount,
    'boundaries': boundaryCount,
    'loops': loopCount,
    'intersections': intersectionCount,
    'adjacencies': adjacencyCount,
    'validTopology': validCount,
    'invalidTopology': invalidCount,
    'averageConfidence': averageConfidence,
    'elapsedMicros': elapsed.inMicroseconds,
  };
}

class TopologyAdvice {
  const TopologyAdvice(this.targetId, this.suggestion, this.reason);
  final String targetId, suggestion, reason;
  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'suggestion': suggestion,
    'reason': reason,
    'consultative': true,
  };
}

class SurfaceTopologyReport {
  const SurfaceTopologyReport({
    required this.id,
    required this.surfaceFittingReportId,
    required this.patches,
    required this.boundaries,
    required this.loops,
    required this.intersections,
    required this.graph,
    required this.analytics,
    required this.advice,
    required this.createdAt,
  });
  final String id, surfaceFittingReportId;
  final List<PatchEntity> patches;
  final List<BoundaryEntity> boundaries;
  final List<LoopEntity> loops;
  final List<IntersectionEntity> intersections;
  final SurfaceTopologyGraph graph;
  final SurfaceTopologyAnalytics analytics;
  final List<TopologyAdvice> advice;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'surfaceFittingReportId': surfaceFittingReportId,
    'patches': patches.map((e) => e.toJson()).toList(),
    'boundaries': boundaries.map((e) => e.toJson()).toList(),
    'loops': loops.map((e) => e.toJson()).toList(),
    'intersections': intersections.map((e) => e.toJson()).toList(),
    'graph': graph.toJson(),
    'analytics': analytics.toJson(),
    'advisor': advice.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'createsSolid': false,
    'finalBrep': false,
  };
}
