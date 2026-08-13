import '../models/decision_models.dart';

class DecisionPolicyProfile {
  const DecisionPolicyProfile(this.policy, this.weights);
  final DecisionPolicy policy;
  final Map<String, double> weights;
  static DecisionPolicyProfile forPolicy(DecisionPolicy policy) {
    final base = <String, double>{
      'recognition': 1,
      'mesh': 1,
      'capture': 1,
      'cost': 1,
      'impact': 1,
      'reuse': 1,
      'complexity': 1,
      'intent': 1,
      'history': 1,
    };
    switch (policy) {
      case DecisionPolicy.precision:
        base
          ..['recognition'] = 2
          ..['mesh'] = 2;
      case DecisionPolicy.speed:
        base
          ..['cost'] = 2
          ..['complexity'] = 1.5;
      case DecisionPolicy.simplicity:
        base
          ..['complexity'] = 2
          ..['reuse'] = 1.5;
      case DecisionPolicy.manufacturing:
        base
          ..['intent'] = 1.8
          ..['impact'] = 1.5;
      case DecisionPolicy.inspection:
        base
          ..['mesh'] = 1.5
          ..['recognition'] = 1.8;
      case DecisionPolicy.meshPreservation:
        base
          ..['mesh'] = 2
          ..['capture'] = 1.7;
    }
    return DecisionPolicyProfile(policy, base);
  }
}
