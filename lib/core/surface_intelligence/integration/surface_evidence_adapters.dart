import '../../engineering_cognition/models/cognition_models.dart';
import '../../engineering_decision/models/decision_models.dart';
import '../../engineering_reconstruction/models/reconstruction_intelligence_models.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../../professional_recognition/models/professional_recognition_models.dart';
import '../models/surface_models.dart';

class SurfaceEvidenceAdapters {
  const SurfaceEvidenceAdapters();
  List<SurfacePlanningEvidence> fromRecognition(
    PrimitiveRecognitionResult result,
  ) => [
    ...result.winner.evidence.map(
      (e) => SurfacePlanningEvidence(
        id: e.id,
        source: 'Recognition:${result.winner.type.name}',
        description: '${result.winner.type.name} ${e.description}',
        value: e.value,
        regionId: result.winner.regionId,
      ),
    ),
    SurfacePlanningEvidence(
      id: '${result.id}-fit',
      source: 'Recognition',
      description: result.winner.type.name,
      value: result.winner.statistics.score,
      regionId: result.winner.regionId,
    ),
  ];
  List<SurfacePlanningEvidence> fromProfessional(
    ProfessionalRecognitionReport report,
  ) => report.primitives
      .map(
        (e) => SurfacePlanningEvidence(
          id: e.recognition.id,
          source: 'Professional Recognition:${e.recognition.winner.type.name}',
          description: e.recognition.explanation.why,
          value: e.recognition.dna.confidence,
          regionId: e.recognition.winner.regionId,
        ),
      )
      .toList();
  List<SurfacePlanningEvidence> fromCognition(CognitionSnapshot snapshot) => [
    ...snapshot.primitives.map(
      (e) => SurfacePlanningEvidence(
        id: 'cognition-${e.regionId}-${e.kind}',
        source: 'Engineering Cognition',
        description: e.kind,
        value: e.confidence,
        regionId: e.regionId,
      ),
    ),
    ...snapshot.surfaces.map(
      (e) => SurfacePlanningEvidence(
        id: e.id,
        source: 'Engineering Cognition',
        description: e.recommendation,
        value: e.confidence,
        ruleIds: e.sourceIds,
      ),
    ),
  ];
  List<SurfacePlanningEvidence> fromDecision(EngineeringDecision decision) =>
      decision.evidence
          .map(
            (e) => SurfacePlanningEvidence(
              id: e.id,
              source: 'Decision Engine:${decision.origin.name}',
              description: '${decision.title} ${e.description}',
              value: e.value,
              regionId: decision.regionId,
              ruleIds: e.ruleIds,
            ),
          )
          .toList();
  List<SurfacePlanningEvidence> fromReconstructionNodes(
    List<ERIPlanNode> nodes,
  ) => nodes
      .where((e) => e.type == ERINodeType.surface)
      .map(
        (e) => SurfacePlanningEvidence(
          id: e.id,
          source: 'Reconstruction Planner',
          description: e.title,
          value: e.confidence,
          ruleIds: e.sourceIds,
        ),
      )
      .toList();
  SurfacePlanningEvidence fromAreiOrKnowledge({
    required String id,
    required String source,
    required String conclusion,
    required double confidence,
    String? regionId,
    List<String> ruleIds = const [],
  }) => SurfacePlanningEvidence(
    id: id,
    source: source,
    description: conclusion,
    value: confidence,
    regionId: regionId,
    ruleIds: ruleIds,
  );
}
