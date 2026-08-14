import '../models/intelligence_models.dart';

class EngineeringKnowledgeBase {
  final Map<String, ProjectKnowledgeSnapshot> _snapshots = {};
  void register(ProjectKnowledgeSnapshot snapshot) =>
      _snapshots[snapshot.projectId] = snapshot;
  ProjectKnowledgeSnapshot get(String projectId) =>
      _snapshots[projectId] ??
      (throw StateError('No project knowledge: $projectId'));
  Map<String, dynamic> facts(String projectId) => get(projectId).toJson();
}
