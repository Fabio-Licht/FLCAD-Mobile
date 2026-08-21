import '../cad_document/cad_document.dart';
import '../feature_lifecycle/feature_lifecycle.dart';

enum ReverseEngineeringStage {
  mesh,
  recognition,
  referenceCurves,
  sketch,
  surface,
  topology,
  solid,
}

enum ReverseEngineeringStageStatus { completed, inProgress, pending, blocked }

class ReverseEngineeringStep {
  const ReverseEngineeringStep(this.stage, this.status, this.count);
  final ReverseEngineeringStage stage;
  final ReverseEngineeringStageStatus status;
  final int count;
  Map<String, dynamic> toJson() => {
    'stage': stage.name,
    'status': status.name,
    'count': count,
  };
}

class ReconstructionTimeline {
  const ReconstructionTimeline(this.id, this.entityIds);
  final String id;
  final List<String> entityIds;
  Map<String, dynamic> toJson() => {'id': id, 'entityIds': entityIds};
}

class ReverseEngineeringStudioState {
  const ReverseEngineeringStudioState({
    required this.steps,
    required this.timelines,
    required this.selectedEntityId,
    required this.currentStage,
    required this.nextAction,
    required this.explanation,
    required this.blockReason,
  });
  final List<ReverseEngineeringStep> steps;
  final List<ReconstructionTimeline> timelines;
  final String? selectedEntityId, blockReason;
  final ReverseEngineeringStage currentStage;
  final String nextAction, explanation;
  Map<String, dynamic> toJson() => {
    'schema': 'flcad.reverse-engineering-studio',
    'version': 1,
    'steps': steps.map((item) => item.toJson()).toList(),
    'timelines': timelines.map((item) => item.toJson()).toList(),
    'selectedEntityId': selectedEntityId,
    'currentStage': currentStage.name,
    'nextAction': nextAction,
    'explanation': explanation,
    'blockReason': blockReason,
  };
}

/// Read-only workflow intelligence. It observes durable project contracts and
/// suggests navigation; it never invokes a modeling command.
class ReverseEngineeringStudioEngine {
  const ReverseEngineeringStudioEngine();

  ReverseEngineeringStudioState evaluate(
    Iterable<CadDocumentEntity> source, {
    String? selectedEntityId,
  }) {
    final entities = {for (final entity in source) entity.id: entity};
    bool live(CadDocumentEntity entity) => entity.data['deleted'] != true;
    final values = entities.values.where(live).toList();
    final counts = <ReverseEngineeringStage, int>{
      ReverseEngineeringStage.mesh: values
          .where(
            (e) => e.kind == CadDocumentEntityKind.import && e.mesh != null,
          )
          .length,
      ReverseEngineeringStage.recognition: values
          .where((e) => e.kind == CadDocumentEntityKind.recognition)
          .length,
      ReverseEngineeringStage.referenceCurves: values
          .where(
            (e) =>
                e.kind == CadDocumentEntityKind.section &&
                e.data['referenceCurve'] == true,
          )
          .length,
      ReverseEngineeringStage.sketch: values
          .where(
            (e) =>
                e.kind == CadDocumentEntityKind.sketch &&
                e.data['sketch'] is Map,
          )
          .length,
      ReverseEngineeringStage.surface: values
          .where((e) => e.kind == CadDocumentEntityKind.surface)
          .length,
      ReverseEngineeringStage.topology: values
          .where(
            (e) =>
                e.data['parentSurfaceId'] != null &&
                (e.kind == CadDocumentEntityKind.edge ||
                    e.kind == CadDocumentEntityKind.vertex),
          )
          .length,
      ReverseEngineeringStage.solid: values
          .where((e) => e.kind == CadDocumentEntityKind.solid)
          .length,
    };
    var firstMissing = ReverseEngineeringStage.mesh;
    for (final stage in ReverseEngineeringStage.values) {
      if ((counts[stage] ?? 0) == 0) {
        firstMissing = stage;
        break;
      }
    }
    final steps = [
      for (final stage in ReverseEngineeringStage.values)
        ReverseEngineeringStep(
          stage,
          (counts[stage] ?? 0) > 0
              ? ReverseEngineeringStageStatus.completed
              : stage == firstMissing
              ? ReverseEngineeringStageStatus.inProgress
              : ReverseEngineeringStageStatus.pending,
          counts[stage] ?? 0,
        ),
    ];
    final selected = selectedEntityId == null
        ? null
        : entities[selectedEntityId];
    final guidance = _guidance(selected, counts);
    return ReverseEngineeringStudioState(
      steps: steps,
      timelines: _timelines(values, entities),
      selectedEntityId: selectedEntityId,
      currentStage: firstMissing,
      nextAction: guidance.$1,
      explanation: guidance.$2,
      blockReason: guidance.$3,
    );
  }

  (String, String, String?) _guidance(
    CadDocumentEntity? selected,
    Map<ReverseEngineeringStage, int> counts,
  ) {
    if (selected == null) {
      if ((counts[ReverseEngineeringStage.mesh] ?? 0) == 0) {
        return (
          'Import Mesh',
          'A mesh starts the reconstruction workflow.',
          'No mesh is loaded.',
        );
      }
      if ((counts[ReverseEngineeringStage.recognition] ?? 0) == 0) {
        return (
          'Select a mesh region',
          'Recognition is the next source of geometric knowledge.',
          null,
        );
      }
      return (
        'Select the latest result',
        'The Studio will show the contextual next step.',
        null,
      );
    }
    if (selected.kind == CadDocumentEntityKind.import) {
      return (
        'Recognition',
        'Select a homogeneous mesh region to understand its likely geometry.',
        null,
      );
    }
    if (selected.kind == CadDocumentEntityKind.recognition) {
      return (
        'Surface Assistant',
        'Review confidence and preview before confirming a Surface.',
        null,
      );
    }
    if (selected.kind == CadDocumentEntityKind.section) {
      return (
        'Sketch Assistant',
        'Use the Reference Curve as guidance for supervised Sketch creation.',
        null,
      );
    }
    if (selected.kind == CadDocumentEntityKind.sketch &&
        selected.data['sketch'] is Map) {
      final hasDependentSurface = _dependents(
        selected,
      ).any((id) => id.startsWith('Surface'));
      return hasDependentSurface
          ? ('Review Surface', 'This Sketch already drives a Surface.', null)
          : (
              'Surface Preview',
              'Validate Sketch Health, preview, then confirm.',
              'Surface remains blocked while Sketch Health is not Ready.',
            );
    }
    if (selected.kind == CadDocumentEntityKind.surface) {
      return (
        'Surface Operations',
        'Inspect boundaries, topology and surface health.',
        null,
      );
    }
    return (
      'Continue reconstruction',
      'Select a workflow Feature for contextual guidance.',
      null,
    );
  }

  List<ReconstructionTimeline> _timelines(
    List<CadDocumentEntity> values,
    Map<String, CadDocumentEntity> entities,
  ) {
    final roots = values
        .where((entity) => entity.kind == CadDocumentEntityKind.surface)
        .toList();
    if (roots.isEmpty) {
      roots.addAll(
        values.where(
          (entity) => entity.kind == CadDocumentEntityKind.recognition,
        ),
      );
    }
    return [
      for (final root in roots)
        ReconstructionTimeline(
          'Timeline:${root.id}',
          _ancestry(root, entities),
        ),
    ];
  }

  List<String> _ancestry(
    CadDocumentEntity root,
    Map<String, CadDocumentEntity> entities,
  ) {
    final ordered = <String>[], visited = <String>{};
    void visit(CadDocumentEntity entity) {
      if (!visited.add(entity.id)) return;
      ordered.add(entity.id);
      final references = <String>{
        ..._references(entity),
        if (entity.data['parameters'] case final Map parameters) ...[
          if (parameters['sourceRecognitionId'] is String)
            parameters['sourceRecognitionId'] as String,
          if (parameters['sourceSketchId'] is String)
            parameters['sourceSketchId'] as String,
        ],
        if (entity.data['sketch'] case final Map sketch)
          if (sketch['metadata'] case final Map metadata)
            if (metadata['sourceSectionId'] is String)
              metadata['sourceSectionId'] as String,
        if (entity.data['section'] case final Map section)
          if (section['meshId'] is String) ...[
            ...entities.values
                .where((candidate) {
                  final raw = candidate.data['recognitionResult'];
                  return raw is Map && raw['meshId'] == section['meshId'];
                })
                .map((candidate) => candidate.id)
                .take(1),
            section['meshId'] as String,
          ],
        if (entity.data['recognitionResult'] case final Map result)
          if (result['meshId'] is String) result['meshId'] as String,
      };
      for (final id in references) {
        final parent = entities[id];
        if (parent != null) visit(parent);
      }
    }

    visit(root);
    return ordered;
  }

  Iterable<String> _references(CadDocumentEntity entity) {
    final lifecycle = entity.data[FeatureLifecycleContract.dataKey];
    if (lifecycle is Map) {
      return (lifecycle['references'] as List? ?? const []).whereType<String>();
    }
    return (entity.data['references'] as List? ?? const []).whereType<String>();
  }

  Iterable<String> _dependents(CadDocumentEntity entity) {
    final lifecycle = entity.data[FeatureLifecycleContract.dataKey];
    return lifecycle is Map
        ? (lifecycle['dependentIds'] as List? ?? const []).whereType<String>()
        : const <String>[];
  }
}
