import '../hybrid/hybrid_object.dart';

class TopologyVersion {
  const TopologyVersion(
    this.sequence,
    this.object,
    this.action,
    this.timestamp,
  );
  final int sequence;
  final HybridObject object;
  final String action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'objectId': object.id,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
  };
}

class TopologyHistory {
  final Map<String, List<TopologyVersion>> _values = {};
  TopologyVersion record(HybridObject object, String action) {
    final list = _values[object.id] ??= [],
        v = TopologyVersion(list.length + 1, object, action, DateTime.now());
    list.add(v);
    return v;
  }

  List<TopologyVersion> get all =>
      List.unmodifiable(_values.values.expand((e) => e));
  HybridObject replay(String id, int sequence) =>
      _values[id]!.firstWhere((v) => v.sequence == sequence).object;
}
