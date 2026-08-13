import '../../engineering_knowledge/reasoning/engineering_reasoner.dart';
import '../../reverse_intelligence/models/intelligence_models.dart';
import '../../smart_regions/models/smart_region.dart';
import '../engineering_intent/intent_engine.dart';
import '../feature_graph/cognition_graph.dart';
import '../feature_recognition/feature_recognizer.dart';
import '../inspection_reasoning/inspection_reasoner.dart';
import '../manufacturing_reasoning/manufacturing_reasoner.dart';
import '../models/cognition_models.dart';
import '../part_analysis/part_analyzer.dart';
import '../recognition/primitive_recognizer.dart';
import '../reconstruction_reasoning/reconstruction_recommender.dart';
import '../reference_reasoning/reference_suggester.dart';
import '../surface_reasoning/surface_suggester.dart';

class CognitionResult {
  const CognitionResult(this.snapshot, this.graph);
  final CognitionSnapshot snapshot;
  final EngineeringCognitionGraph graph;
}

class EngineeringCognitionOrchestrator {
  EngineeringCognitionOrchestrator({EngineeringReasoner? knowledge})
    : featureRecognizer = AutomaticFeatureRecognizer(
        knowledge ?? EngineeringReasoner(),
      );
  final primitiveRecognizer = const AutomaticPrimitiveRecognizer();
  final AutomaticFeatureRecognizer featureRecognizer;
  final intentEngine = const EngineeringIntentEngine();
  final partAnalyzer = const CognitionPartAnalyzer();
  final referenceSuggester = const ReferenceSuggestionEngine();
  final surfaceSuggester = const SurfaceSuggestionEngine();
  final reconstruction = const ReconstructionRecommendationEngine();
  final manufacturing = const ManufacturingCognitionReasoner();
  final inspection = const InspectionCognitionReasoner();
  CognitionResult analyze(
    ReasoningSnapshot arei, {
    List<SmartRegion> regions = const [],
    Map<String, dynamic> facts = const {},
  }) {
    final primitives = primitiveRecognizer.recognize(arei, regions),
        features = featureRecognizer.recognize(primitives, facts: facts),
        intents = intentEngine.infer(features),
        parts = partAnalyzer.analyze(arei, features),
        references = referenceSuggester.suggest(primitives, features),
        surfaces = surfaceSuggester.suggest(primitives),
        plan = reconstruction.recommend(references, surfaces, features),
        manufacturingResult = manufacturing.reason(features, parts),
        inspectionResult = inspection.reason(features, intents),
        snapshot = CognitionSnapshot(
          projectId: arei.projectId,
          meshId: arei.meshId,
          primitives: primitives,
          features: features,
          intents: intents,
          partClassifications: parts,
          references: references,
          surfaces: surfaces,
          reconstruction: plan,
          manufacturing: manufacturingResult,
          inspection: inspectionResult,
          createdAt: DateTime.now().toUtc(),
        ),
        graph = _graph(
          arei.meshId,
          features,
          intents,
          references,
          surfaces,
          manufacturingResult,
          inspectionResult,
        );
    return CognitionResult(snapshot, graph);
  }

  EngineeringCognitionGraph _graph(
    String meshId,
    List<RecognizedFeature> features,
    List<EngineeringIntent> intents,
    List<CognitionSuggestion> references,
    List<CognitionSuggestion> surfaces,
    List<ManufacturingAssessment> manufacturing,
    List<InspectionAssessment> inspection,
  ) {
    final g = EngineeringCognitionGraph()
      ..add(CognitionNode(meshId, 'part', const {}));
    for (final f in features) {
      g.add(
        CognitionNode(f.id, 'feature', {
          'kind': f.kind,
          'confidence': f.confidence,
        }),
      );
      g.connect(CognitionEdge(meshId, f.id, 'contains', f.confidence));
    }
    for (final i in intents) {
      final id = 'function:${i.function}';
      g.add(CognitionNode(id, 'function', {'confidence': i.confidence}));
      for (final f in i.featureIds) {
        g.connect(CognitionEdge(f, id, 'performs', i.confidence));
      }
    }
    for (final r in references) {
      g.add(
        CognitionNode(r.id, 'reference', {'recommendation': r.recommendation}),
      );
      g.connect(CognitionEdge(meshId, r.id, 'suggests', r.confidence));
    }
    for (final s in surfaces) {
      g.add(
        CognitionNode(s.id, 'surface', {'recommendation': s.recommendation}),
      );
      g.connect(CognitionEdge(meshId, s.id, 'suggests', s.confidence));
    }
    for (final m in manufacturing) {
      final id = 'process:${m.process}';
      g.add(CognitionNode(id, 'process', const {}));
      g.connect(CognitionEdge(m.featureId, id, 'manufacturedBy', m.confidence));
    }
    for (final i in inspection) {
      final id = 'inspection:${i.targetId}';
      g.add(CognitionNode(id, 'inspection', {'role': i.role}));
      g.connect(CognitionEdge(i.targetId, id, 'inspectedBy', i.confidence));
    }
    return g;
  }
}
