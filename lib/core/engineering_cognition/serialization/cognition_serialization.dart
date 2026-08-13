import 'dart:convert';
import '../models/cognition_models.dart';

class CognitionSerialization {
  const CognitionSerialization();
  String encode(CognitionSnapshot s) => jsonEncode({
    'schema': 'flcad.engineering-cognition',
    'version': '0.8.0',
    'projectId': s.projectId,
    'meshId': s.meshId,
    'createdAt': s.createdAt.toIso8601String(),
    'primitives': s.primitives
        .map(
          (p) => {
            'kind': p.kind,
            'confidence': p.confidence,
            'regionId': p.regionId,
            'provenance': p.provenance,
            'evidence': p.evidence.map((e) => e.toJson()).toList(),
            'discardedAlternatives': p.discardedAlternatives,
          },
        )
        .toList(),
    'features': s.features
        .map(
          (f) => {
            'id': f.id,
            'kind': f.kind,
            'confidence': f.confidence,
            'provenance': f.provenance,
            'regionIds': f.regionIds,
            'relations': f.relatedFeatureIds,
            'ruleIds': f.knowledgeRuleIds,
            'explanation': f.explanation,
            'discardedAlternatives': f.discardedAlternatives,
            'evidence': f.evidence.map((e) => e.toJson()).toList(),
          },
        )
        .toList(),
    'intents': s.intents
        .map(
          (i) => {
            'function': i.function,
            'confidence': i.confidence,
            'explanation': i.explanation,
            'featureIds': i.featureIds,
          },
        )
        .toList(),
    'part': s.partClassifications
        .map((p) => {'kind': p.kind, 'probability': p.probability})
        .toList(),
    'references': _suggestions(s.references),
    'surfaces': _suggestions(s.surfaces),
    'reconstruction': _suggestions(s.reconstruction),
  });
  List<Map<String, dynamic>> _suggestions(List<CognitionSuggestion> values) =>
      values
          .map(
            (s) => {
              'id': s.id,
              'kind': s.kind.name,
              'recommendation': s.recommendation,
              'order': s.order,
              'confidence': s.confidence,
              'reason': s.reason,
              'sourceIds': s.sourceIds,
            },
          )
          .toList();
}
