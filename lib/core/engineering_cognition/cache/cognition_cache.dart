import '../orchestrator/cognition_orchestrator.dart';

class CognitionCache {
  final Map<String, CognitionResult> _values = {};
  CognitionResult? get(String key) => _values[key];
  void put(String key, CognitionResult value) => _values[key] = value;
  void clear() => _values.clear();
}
