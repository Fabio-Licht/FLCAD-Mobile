import 'dart:math' as math;

import '../../../core/adaptive_surface/continuity/surface_continuity.dart';
import '../../../core/adaptive_surface/models/surface_geometry.dart';
import '../../../core/feature_lifecycle/feature_update_solver.dart';
import '../../../core/parametric_solver/parametric_solver.dart';
import '../../../core/recognition_engine/recognition_result.dart';
import '../../../core/surface_assistant/surface_assistant.dart';
import '../../../core/surface_generation/api/surface_generation_api.dart';
import '../../../core/surface_generation/models/surface_generation_models.dart';
import '../../../core/surface_generation/models/surface_topology.dart';
import '../../../core/surface_intelligence/models/surface_models.dart';

class RecognitionSurfaceAssistantAdapter {
  const RecognitionSurfaceAssistantAdapter({
    this.updates = const FeatureUpdateSolver(),
  });

  final FeatureUpdateSolver updates;

  Future<GeneratedSurface> confirm({
    required String featureId,
    required RecognitionResult recognition,
    required SurfaceAssistantSuggestion suggestion,
    required SurfaceGenerationApi generation,
  }) => updates.update<Future<GeneratedSurface>>(
    request: ParametricSolveRequest(
      first: '${recognition.id}:knowledge',
      second: '$featureId:definition',
      degreesOfFreedom: [
        ParametricDegreeOfFreedom('${recognition.id}:knowledge', fixed: true),
        ParametricDegreeOfFreedom(
          '$featureId:definition',
          parameterIds: {'$featureId:recognitionConfidence'},
        ),
      ],
      parameters: [
        ParametricParameter(
          '$featureId:recognitionConfidence',
          recognition.confidence,
        ),
      ],
      anchors: {'${recognition.id}:knowledge'},
    ),
    apply: (_) async {
      if (!suggestion.canCreate) {
        throw StateError('This suggestion is not approved for CAD creation.');
      }
      final parameters = recognition.parameters;
      final kind = _kind(recognition.type);
      final candidate = SurfaceCandidate(
        id: '${recognition.id}:surface-assistant',
        kind: kind,
        classification: SurfaceClassification.analytical,
        confidence: recognition.confidence,
        evidence: [
          SurfacePlanningEvidence(
            id: recognition.id,
            source: 'Recognition Result',
            description: recognition.quality,
            value: recognition.confidence,
            regionId: recognition.regionId,
          ),
        ],
        regionIds: [recognition.regionId],
        boundaries: const [],
        quality: recognition.confidence,
        coverage: recognition.confidence,
        predictedContinuity: SurfaceContinuityLevel.g0,
        justification: 'Explicitly confirmed Surface Assistant suggestion.',
      );
      final generationParameters = switch (recognition.type) {
        RecognitionResultType.plane => {
          'origin': _vector(parameters['origin']),
          'normal': _vector(parameters['normal']),
          'lowerBound': -_planeExtent(parameters),
          'upperBound': _planeExtent(parameters),
        },
        RecognitionResultType.cylinder => {
          'axisOrigin': _vector(parameters['origin']),
          'axisDirection': _vector(parameters['axis']),
          'radius': _number(parameters['radius']),
          'lowerBound': 0.0,
          'upperBound': 2 * math.pi,
        },
        RecognitionResultType.cone => {
          'apex': _vector(parameters['origin']),
          'axisDirection': _vector(parameters['axis']),
          'semiAngle': _number(parameters['halfAngle']),
          'lowerBound': 0.0,
          'upperBound': _number(parameters['length'], fallback: 1),
        },
        RecognitionResultType.sphere => {
          'center': _vector(parameters['center']),
          'radius': _number(parameters['radius']),
          'lowerBound': -math.pi / 2,
          'upperBound': math.pi / 2,
        },
        RecognitionResultType.fillet => {
          'center': _vector(parameters['center']),
          'axisDirection': _vector(parameters['axis']),
          'majorRadius': _number(parameters['majorRadius']),
          'minorRadius': _number(parameters['minorRadius']),
        },
        RecognitionResultType.freeform => throw StateError(
          'Freeform suggestions require a future supervised Surface tool.',
        ),
      };
      final result = await generation.engine.generate(
        SurfaceGenerationRequest(
          candidate: candidate,
          featureId: featureId,
          origin: 'surface-assistant',
          parameters: generationParameters,
        ),
      );
      if (!result.success || result.surface == null) {
        throw StateError(result.diagnostics.map((e) => e.message).join('; '));
      }
      final surface = result.surface!;
      return GeneratedSurface(
        surfaceId: surface.surfaceId,
        projectId: surface.projectId,
        kind: surface.kind,
        origin: 'surface-assistant',
        regionIds: surface.regionIds,
        evidenceIds: {...surface.evidenceIds, recognition.id}.toList(),
        featureId: surface.featureId,
        handle: surface.handle,
        revision: surface.revision,
        timestamp: surface.timestamp,
        parameters: {
          ...surface.parameters,
          'sourceRecognitionId': recognition.id,
          'recognitionConfidence': recognition.confidence,
          'assistantStrategy': suggestion.strategy.name,
          'displayMode': SurfaceDisplayMode.shadedWithEdges.name,
          'topology': const SurfaceTopology(
            loops: [],
            edges: [],
            vertices: [],
            area: 0,
            perimeter: 0,
          ).toJson(),
          'health': const {'recognitionDriven': true},
        },
        continuity: surface.continuity,
        valid: surface.valid,
        confidence: surface.confidence,
        diagnostics: surface.diagnostics,
      );
    },
  );

  SurfaceKind _kind(RecognitionResultType type) => switch (type) {
    RecognitionResultType.plane => SurfaceKind.plane,
    RecognitionResultType.cylinder => SurfaceKind.cylinder,
    RecognitionResultType.cone => SurfaceKind.cone,
    RecognitionResultType.sphere => SurfaceKind.sphere,
    RecognitionResultType.fillet => SurfaceKind.torus,
    RecognitionResultType.freeform => SurfaceKind.freeform,
  };

  List<double> _vector(dynamic value) =>
      (value as List).cast<num>().map((item) => item.toDouble()).toList();
  double _number(dynamic value, {double fallback = 0}) =>
      value is num ? value.toDouble() : fallback;
  double _planeExtent(Map<String, dynamic> parameters) {
    final area = _number(parameters['area'], fallback: 4);
    return math.sqrt(area <= 0 ? 1 : area) / 2;
  }
}
