class EngineeringDecision {
  const EngineeringDecision({
    required this.id,
    required this.projectId,
    required this.branchId,
    required this.entityId,
    required this.action,
    required this.reason,
    required this.timestamp,
    required this.sequence,
    this.parameters = const {},
    this.parentDecisionId,
  });
  final String id, projectId, branchId, entityId, action, reason;
  final DateTime timestamp;
  final int sequence;
  final Map<String, dynamic> parameters;
  final String? parentDecisionId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'branchId': branchId,
    'entityId': entityId,
    'action': action,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
    'sequence': sequence,
    'parameters': parameters,
    'parentDecisionId': parentDecisionId,
  };
  factory EngineeringDecision.fromJson(Map<String, dynamic> j) =>
      EngineeringDecision(
        id: j['id'] as String,
        projectId: j['projectId'] as String,
        branchId: j['branchId'] as String,
        entityId: j['entityId'] as String,
        action: j['action'] as String,
        reason: j['reason'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
        sequence: j['sequence'] as int,
        parameters: (j['parameters'] as Map? ?? const {}).cast(),
        parentDecisionId: j['parentDecisionId'] as String?,
      );
}

class TimelineBranch {
  const TimelineBranch(this.id, this.name, this.parentId, this.forkSequence);
  final String id, name;
  final String? parentId;
  final int forkSequence;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
    'forkSequence': forkSequence,
  };
}

class EngineeringTimeline {
  final List<EngineeringDecision> decisions = [];
  final Map<String, TimelineBranch> branches = {
    'main': const TimelineBranch('main', 'Main', null, 0),
  };
  void append(EngineeringDecision d) => decisions.add(d);
  void branch(TimelineBranch b) {
    if (b.parentId != null && !branches.containsKey(b.parentId)) {
      throw StateError('Parent branch missing');
    }
    branches[b.id] = b;
  }

  List<EngineeringDecision> replay(String branchId, {int? until}) =>
      decisions
          .where(
            (d) =>
                d.branchId == branchId && d.sequence <= (until ?? 0x7fffffff),
          )
          .toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
  List<EngineeringDecision> merge(String target, String source) =>
      [...replay(target), ...replay(source)]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
}
