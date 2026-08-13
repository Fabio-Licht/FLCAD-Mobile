import '../models/knowledge_models.dart';

class EngineeringPattern {
  const EngineeringPattern({
    required this.id,
    required this.name,
    required this.conditions,
    required this.conclusion,
    required this.confidence,
    required this.provenance,
  });
  final String id, name, conclusion;
  final Map<String, Object> conditions;
  final double confidence;
  final KnowledgeProvenance provenance;
  KnowledgeInference? match(EngineeringCase c) {
    final evidence = <KnowledgeEvidence>[];
    for (final entry in conditions.entries) {
      final actual = c.facts[entry.key];
      if (entry.value is num) {
        if (actual is! num ||
            actual.toDouble() < (entry.value as num).toDouble()) {
          return null;
        }
      } else if (actual != entry.value) {
        return null;
      }
      evidence.add(
        KnowledgeEvidence(
          '$id:${entry.key}',
          'Pattern condition ${entry.key}',
          1,
          'engineering.case',
        ),
      );
    }
    return KnowledgeInference(
      conclusion: conclusion,
      confidence: confidence,
      explanation:
          'Pattern $name matched ${conditions.length} observed conditions.',
      evidence: evidence,
      ruleIds: [id],
    );
  }
}

class EngineeringPatternLibrary {
  EngineeringPatternLibrary(Iterable<EngineeringPattern> patterns)
    : patterns = List.unmodifiable(patterns);
  final List<EngineeringPattern> patterns;
  List<KnowledgeInference> match(EngineeringCase c) =>
      patterns.map((p) => p.match(c)).whereType<KnowledgeInference>().toList();
  factory EngineeringPatternLibrary.foundation() =>
      EngineeringPatternLibrary(const [
        EngineeringPattern(
          id: 'pattern.symmetricFourHoles',
          name: 'Four symmetric holes',
          conditions: {'hole.count': 4, 'symmetry.planar': true},
          conclusion: 'feature.flange',
          confidence: .86,
          provenance: KnowledgeProvenance(
            'FLCAD Pattern Library',
            '0.7.0',
            verified: true,
          ),
        ),
        EngineeringPattern(
          id: 'pattern.cylinderFillet',
          name: 'Cylinder and fillet seat',
          conditions: {'surface.cylinder': true, 'feature.fillet': true},
          conclusion: 'feature.seat',
          confidence: .78,
          provenance: KnowledgeProvenance(
            'FLCAD Pattern Library',
            '0.7.0',
            verified: true,
          ),
        ),
        EngineeringPattern(
          id: 'pattern.repeatedRibs',
          name: 'Repeated reinforcement ribs',
          conditions: {'rib.count': 2, 'pattern.repetition': true},
          conclusion: 'function.reinforcement',
          confidence: .82,
          provenance: KnowledgeProvenance(
            'FLCAD Pattern Library',
            '0.7.0',
            verified: true,
          ),
        ),
      ]);
}
