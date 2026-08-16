// ignore_for_file: curly_braces_in_flow_control_structures

class BridgeAssistantMessage {
  const BridgeAssistantMessage({
    required this.title,
    required this.evidence,
    required this.confidence,
    required this.alternatives,
    required this.justification,
  });
  final String title, justification;
  final List<String> evidence, alternatives;
  final double confidence;
}

class BridgeAssistantSync {
  final List<BridgeAssistantMessage> messages = [];
  void publish(BridgeAssistantMessage message) {
    if (message.evidence.isEmpty)
      throw StateError('Assistant bridge messages require evidence.');
    messages.add(message);
  }
}
