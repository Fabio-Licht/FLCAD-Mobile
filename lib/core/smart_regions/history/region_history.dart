import '../selection/triangle_selection.dart';

class RegionVersion {
  const RegionVersion({
    required this.version,
    required this.regionId,
    required this.selection,
    required this.timestamp,
    required this.reason,
  });
  final int version;
  final String regionId, reason;
  final TriangleSelection selection;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'version': version,
    'regionId': regionId,
    'selection': selection.toRanges(),
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
  };
}

class RegionHistory {
  final Map<String, List<RegionVersion>> _versions = {};
  List<RegionVersion> versions(String id) =>
      List.unmodifiable(_versions[id] ?? const []);
  RegionVersion record(String id, TriangleSelection selection, String reason) {
    final list = _versions[id] ??= [];
    final value = RegionVersion(
      version: list.length + 1,
      regionId: id,
      selection: selection,
      timestamp: DateTime.now(),
      reason: reason,
    );
    list.add(value);
    return value;
  }

  TriangleSelection restore(String id, int version) =>
      versions(id).firstWhere((v) => v.version == version).selection;
}
