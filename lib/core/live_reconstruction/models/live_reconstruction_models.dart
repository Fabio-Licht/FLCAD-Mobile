import '../../surface_operations/models/surface_operation_models.dart';

enum ReconstructionState {
  created,
  previewed,
  validated,
  updated,
  committed,
  rolledBack,
  cancelled,
  unsupported,
  failed,
}

class ReconstructionDependencyGraph {
  const ReconstructionDependencyGraph(this.nodes, this.edges);
  final Map<String, String> nodes;
  final Map<String, Set<String>> edges;
  Set<String> downstream(Iterable<String> roots) {
    final result = <String>{}, queue = [...roots];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (!result.add(current)) continue;
      queue.addAll(edges[current] ?? const {});
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes,
    'edges': edges.map((k, v) => MapEntry(k, v.toList()..sort())),
  };
}

class AffectedObjects {
  const AffectedObjects({
    required this.regions,
    required this.patches,
    required this.boundaries,
    required this.continuity,
    required this.validation,
    required this.analytics,
    required this.reflection,
    required this.zebra,
    required this.draft,
    required this.heatMap,
  });
  final Set<String> regions,
      patches,
      boundaries,
      continuity,
      validation,
      analytics,
      reflection,
      zebra,
      draft,
      heatMap;
  Set<String> get all => {
    ...regions,
    ...patches,
    ...boundaries,
    ...continuity,
    ...validation,
    ...analytics,
    ...reflection,
    ...zebra,
    ...draft,
    ...heatMap,
  };
  Map<String, dynamic> toJson() => {
    'regions': regions.toList()..sort(),
    'patches': patches.toList()..sort(),
    'boundaries': boundaries.toList()..sort(),
    'continuity': continuity.toList()..sort(),
    'validation': validation.toList()..sort(),
    'analytics': analytics.toList()..sort(),
    'reflection': reflection.toList()..sort(),
    'zebra': zebra.toList()..sort(),
    'draft': draft.toList()..sort(),
    'heatMap': heatMap.toList()..sort(),
    'total': all.length,
  };
}

class ReconstructionPreview {
  const ReconstructionPreview({
    required this.id,
    required this.operationId,
    required this.affected,
    required this.originalSurfaceIds,
    required this.createdAt,
  });
  final String id, operationId;
  final AffectedObjects affected;
  final Map<String, String> originalSurfaceIds;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'operationId': operationId,
    'affected': affected.toJson(),
    'originalSurfaceIds': originalSurfaceIds,
    'incremental': true,
    'fullProjectRecalculation': false,
    'geometryModified': false,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ReconstructionValidation {
  const ReconstructionValidation(this.valid, this.errors);
  final bool valid;
  final List<String> errors;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'errors': errors,
    'incrementalScope': true,
  };
}

class ReconstructionAnalytics {
  const ReconstructionAnalytics({
    required this.updateTime,
    required this.affectedObjects,
    required this.patches,
    required this.boundaries,
    required this.continuityUpdates,
    required this.validationUpdates,
    required this.rollbacks,
    required this.cancellations,
    required this.commits,
  });
  final Duration updateTime;
  final int affectedObjects,
      patches,
      boundaries,
      continuityUpdates,
      validationUpdates,
      rollbacks,
      cancellations,
      commits;
  Map<String, dynamic> toJson() => {
    'updateMicros': updateTime.inMicroseconds,
    'affectedObjects': affectedObjects,
    'patches': patches,
    'boundaries': boundaries,
    'continuityUpdates': continuityUpdates,
    'validationUpdates': validationUpdates,
    'rollbacks': rollbacks,
    'cancellations': cancellations,
    'commits': commits,
  };
}

class ReconstructionAdvice {
  const ReconstructionAdvice(this.message);
  final String message;
  Map<String, dynamic> toJson() => {
    'message': message,
    'consultative': true,
    'automaticAction': false,
  };
}

class LiveReconstruction {
  const LiveReconstruction({
    required this.id,
    required this.operation,
    required this.graph,
    required this.state,
    required this.timeline,
    required this.analytics,
    required this.advice,
    required this.createdAt,
    this.preview,
    this.validation,
    this.updatedObjects = const {},
  });
  final String id;
  final SurfaceOperation operation;
  final ReconstructionDependencyGraph graph;
  final ReconstructionState state;
  final ReconstructionPreview? preview;
  final ReconstructionValidation? validation;
  final Set<String> updatedObjects;
  final List<Map<String, dynamic>> timeline;
  final ReconstructionAnalytics analytics;
  final List<ReconstructionAdvice> advice;
  final DateTime createdAt;
  LiveReconstruction copyWith({
    SurfaceOperation? operation,
    ReconstructionState? state,
    ReconstructionPreview? preview,
    ReconstructionValidation? validation,
    Set<String>? updatedObjects,
    List<Map<String, dynamic>>? timeline,
    ReconstructionAnalytics? analytics,
    List<ReconstructionAdvice>? advice,
  }) => LiveReconstruction(
    id: id,
    operation: operation ?? this.operation,
    graph: graph,
    state: state ?? this.state,
    preview: preview ?? this.preview,
    validation: validation ?? this.validation,
    updatedObjects: updatedObjects ?? this.updatedObjects,
    timeline: timeline ?? this.timeline,
    analytics: analytics ?? this.analytics,
    advice: advice ?? this.advice,
    createdAt: createdAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'operationId': operation.id,
    'state': state.name,
    'graph': graph.toJson(),
    'preview': preview?.toJson(),
    'validation': validation?.toJson(),
    'updatedObjects': updatedObjects.toList()..sort(),
    'timeline': timeline,
    'analytics': analytics.toJson(),
    'advisor': advice.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'incremental': true,
  };
}
