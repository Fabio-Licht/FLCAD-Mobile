class EngineeringKnowledge {
  const EngineeringKnowledge(
    this.projectId,
    this.entityId,
    this.facts,
    this.relations,
    this.provenance,
  );
  final String projectId, entityId;
  final Map<String, dynamic> facts;
  final List<String> relations, provenance;
}

typedef KnowledgeProvider =
    Future<EngineeringKnowledge?> Function(String projectId, String entityId);

class EngineeringKnowledgeBus {
  final List<KnowledgeProvider> _providers = [];
  void register(KnowledgeProvider provider) => _providers.add(provider);
  Future<List<EngineeringKnowledge>> resolve(
    String projectId,
    String entityId,
  ) async {
    final values = await Future.wait(
      _providers.map((p) => p(projectId, entityId)),
    );
    return values.whereType<EngineeringKnowledge>().toList();
  }
}
