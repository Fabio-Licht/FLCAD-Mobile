import '../models/intelligence_models.dart';

abstract interface class ReverseAgent<I, O> {
  String get role;
  Future<O> execute(I input);
}

class AgentMessage<T> {
  const AgentMessage(this.correlationId, this.sender, this.payload);
  final String correlationId, sender;
  final T payload;
}

abstract interface class ReverseAgentCoordinator {
  Future<StrategyDecision> coordinate(ReasoningSnapshot snapshot);
}
