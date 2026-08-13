import '../models/intelligence_models.dart';

class EngineeringExperience {
  const EngineeringExperience({
    required this.projectId,
    required this.meshSignature,
    required this.strategyId,
    required this.outcome,
    required this.recordedAt,
    this.correction,
  });
  final String projectId, meshSignature, strategyId, outcome;
  final DateTime recordedAt;
  final String? correction;
}

abstract interface class EngineeringMemory {
  Future<void> remember(EngineeringExperience experience);
  Future<List<EngineeringExperience>> similar(String meshSignature);
}

class InMemoryEngineeringMemory implements EngineeringMemory {
  final List<EngineeringExperience> _records = [];
  @override
  Future<void> remember(EngineeringExperience e) async => _records.add(e);
  @override
  Future<List<EngineeringExperience>> similar(String signature) async =>
      List.unmodifiable(_records.where((e) => e.meshSignature == signature));
}

String observationSignature(MeshObservation o) =>
    '${o.vertexCount}:${o.triangleCount}:${o.boundaryEdgeCount}:${o.normalCoherence.toStringAsFixed(2)}';
