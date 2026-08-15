import '../../surface_recognition/models/surface_recognition_models.dart';
import '../models/primitive_intelligence_models.dart';

class PrimitiveRecognitionAdapter {
  const PrimitiveRecognitionAdapter();
  List<PrimitiveObservation> fromReport(SurfaceRecognitionReport report) =>
      List.unmodifiable(
        report.classifications.map((value) {
          final measures = <String, double>{
            'area': value.region.area,
            'continuity': value.quality,
            for (final entry in value.parameters.entries)
              if (entry.value is num)
                entry.key: (entry.value as num).toDouble(),
          };
          final vectors = <String, List<double>>{};
          for (final entry in value.parameters.entries) {
            final raw = entry.value;
            if (raw is List && raw.length == 3 && raw.every((e) => e is num)) {
              vectors[entry.key] = raw
                  .cast<num>()
                  .map((e) => e.toDouble())
                  .toList();
            }
          }
          return PrimitiveObservation(
            id: value.region.id,
            type: value.type,
            measures: measures,
            vectors: vectors,
            adjacentIds: report.graph.edges[value.region.id] ?? const {},
            recognitionConfidence: value.confidence,
          );
        }),
      );
}

abstract interface class PrimitiveIntelligenceIntegration {
  void onSessionChanged(PrimitiveIntelligenceSession session);
}

class PrimitiveIntelligenceModuleGraph {
  PrimitiveIntelligenceModuleGraph(Iterable<String> modules)
    : modules = Set.unmodifiable(modules);
  final Set<String> modules;
  static const officialModules = {
    'Recognition',
    'Topology',
    'Continuity',
    'AI Foundation',
    'Primitive Intelligence',
    'Surface Operations',
    'Live Reconstruction',
    'Manufacturing',
  };
  bool get isComplete => modules.containsAll(officialModules);
}

class OfficialPrimitiveIntelligenceIntegration
    implements PrimitiveIntelligenceIntegration {
  OfficialPrimitiveIntelligenceIntegration({
    required this.project,
    required this.aiFoundation,
    required this.workspace,
    required this.propertyInspector,
    required this.analytics,
    PrimitiveIntelligenceModuleGraph? graph,
  }) : graph =
           graph ??
           PrimitiveIntelligenceModuleGraph(
             PrimitiveIntelligenceModuleGraph.officialModules,
           );
  final Map<String, dynamic> project,
      aiFoundation,
      workspace,
      propertyInspector,
      analytics;
  final PrimitiveIntelligenceModuleGraph graph;
  @override
  void onSessionChanged(PrimitiveIntelligenceSession session) {
    project['primitiveIntelligence'] = session.toJson();
    aiFoundation['primitiveContext'] = session.context.toJson();
    aiFoundation['primitiveHypotheses'] = session.hypotheses
        .map((e) => e.toJson())
        .toList();
    workspace['primitiveIntelligence'] = true;
    propertyInspector['primitiveIntelligenceSessionId'] = session.id;
    analytics['primitivesAnalyzed'] = session.hypotheses.length;
  }
}
