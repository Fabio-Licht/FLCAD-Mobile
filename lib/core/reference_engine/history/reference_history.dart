import '../models/reference_entity.dart';

class ReferenceVersion {
  const ReferenceVersion(
    this.version,
    this.reference,
    this.reason,
    this.timestamp,
  );
  final int version;
  final ReferenceEntity reference;
  final String reason;
  final DateTime timestamp;
}

class ReferenceHistory {
  final Map<String, List<ReferenceVersion>> _versions = {};
  ReferenceVersion record(ReferenceEntity reference, String reason) {
    final list = _versions[reference.id] ??= [];
    final value = ReferenceVersion(
      list.length + 1,
      reference,
      reason,
      DateTime.now(),
    );
    list.add(value);
    return value;
  }

  List<ReferenceVersion> versions(String id) =>
      List.unmodifiable(_versions[id] ?? const []);
  List<ReferenceVersion> get all =>
      List.unmodifiable(_versions.values.expand((value) => value));
  ReferenceEntity restore(String id, int version) =>
      versions(id).firstWhere((v) => v.version == version).reference;
}
