import '../brain/reverse_brain.dart';

class ReverseIntelligenceCache {
  final Map<String, ReverseBrainResult> _values = {};
  ReverseBrainResult? get(String projectId, String meshId) =>
      _values['$projectId:$meshId'];
  void put(String projectId, String meshId, ReverseBrainResult result) =>
      _values['$projectId:$meshId'] = result;
  void invalidateProject(String projectId) =>
      _values.removeWhere((key, value) => key.startsWith('$projectId:'));
}
