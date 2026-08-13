import '../../engineering/graph/engineering_graph.dart';
import '../models/decision_models.dart';

class DecisionGraph {
  DecisionGraph({EngineeringGraph? engineeringGraph})
    : engineeringGraph = engineeringGraph ?? EngineeringGraph();
  final EngineeringGraph engineeringGraph;
  final Map<String, EngineeringDecision> _decisions = {};
  void add(EngineeringDecision decision) {
    for (final dependency in decision.dependencies) {
      if (!_decisions.containsKey(dependency)) {
        throw StateError('Missing decision dependency $dependency');
      }
    }
    _decisions[decision.id] = decision;
    engineeringGraph.addNode(
      EngineeringGraphNode(
        decision.id,
        EngineeringNodeType.ai,
        metadata: {
          'domain': 'decision',
          'type': decision.type.name,
          'confidence': decision.confidence,
        },
      ),
    );
    for (final dependency in decision.dependencies) {
      engineeringGraph.connect(
        EngineeringGraphEdge(dependency, decision.id, 'decision-dependency'),
      );
    }
  }

  void update(EngineeringDecision decision) {
    if (!_decisions.containsKey(decision.id)) {
      throw StateError('Decision ${decision.id} not found');
    }
    _decisions[decision.id] = decision;
  }

  EngineeringDecision? find(String id) => _decisions[id];
  Set<String> impact(String id) => engineeringGraph.impact(id);
  List<EngineeringDecision> get decisions =>
      List.unmodifiable(_decisions.values);
}
