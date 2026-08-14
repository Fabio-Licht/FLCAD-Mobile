import '../../utils/id_generator.dart';

class InteractiveHistoryEntry {
  InteractiveHistoryEntry({
    required this.kind,
    required this.subjectId,
    required this.workflowStep,
    required this.result,
    String? id,
  }) : id = id ?? 'interactive-history:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, kind, subjectId, workflowStep, result;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'subjectId': subjectId,
    'workflowStep': workflowStep,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };
}

class InteractiveHistory {
  final List<InteractiveHistoryEntry> entries = [];
  void add(InteractiveHistoryEntry entry) => entries.add(entry);
}

class InteractiveTimeline extends InteractiveHistory {}
