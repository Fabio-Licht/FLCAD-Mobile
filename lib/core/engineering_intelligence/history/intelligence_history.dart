import '../../utils/id_generator.dart';

enum IntelligenceHistoryAction {
  analyzed,
  recommended,
  accepted,
  rejected,
  ignored,
  impactObserved,
}

class IntelligenceHistoryEntry {
  IntelligenceHistoryEntry({
    required this.action,
    required this.targetId,
    this.impact = 0,
    this.gain = 0,
    this.accuracy = 0,
  }) : id = 'intelligence-history:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, targetId;
  final IntelligenceHistoryAction action;
  final DateTime timestamp;
  final double impact, gain, accuracy;
  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': targetId,
    'action': action.name,
    'timestamp': timestamp.toIso8601String(),
    'impact': impact,
    'gain': gain,
    'accuracy': accuracy,
  };
}

class IntelligenceHistory {
  final List<IntelligenceHistoryEntry> entries = [];
  void record(
    IntelligenceHistoryAction action,
    String target, {
    double impact = 0,
    double gain = 0,
    double accuracy = 0,
  }) => entries.add(
    IntelligenceHistoryEntry(
      action: action,
      targetId: target,
      impact: impact,
      gain: gain,
      accuracy: accuracy,
    ),
  );
}
