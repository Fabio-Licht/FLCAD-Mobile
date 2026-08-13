import '../models/decision_models.dart';

abstract interface class DecisionPlugin {
  String get id;
  String get version;
  bool get compatible;
  Iterable<DecisionEvidence> evidence(DecisionRequest request);
  DecisionCriteria evaluate(DecisionRequest request);
}

class DecisionPluginRegistry {
  final Map<String, DecisionPlugin> _plugins = {};
  void register(DecisionPlugin plugin) {
    if (!plugin.compatible) {
      throw StateError('Decision plugin ${plugin.id} is incompatible');
    }
    if (_plugins.containsKey(plugin.id)) {
      throw StateError('Decision plugin ${plugin.id} already registered');
    }
    _plugins[plugin.id] = plugin;
  }

  DecisionPlugin? remove(String id) => _plugins.remove(id);
  List<DecisionPlugin> get plugins => List.unmodifiable(_plugins.values);
}

abstract interface class OnnxDecisionEvaluatorContract {
  Future<Map<String, double>> evaluate(List<double> features);
}

abstract interface class TfliteDecisionEvaluatorContract {
  Future<Map<String, double>> evaluate(List<double> features);
}
