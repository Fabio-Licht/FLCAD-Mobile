import '../features/engineering_feature.dart';

class FeatureVersion {
  const FeatureVersion(
    this.sequence,
    this.feature,
    this.action,
    this.timestamp,
    this.branchId,
  );
  final int sequence;
  final EngineeringFeature feature;
  final String action, branchId;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'featureId': feature.id,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
    'branchId': branchId,
  };
}

class ParametricHistory {
  final Map<String, List<FeatureVersion>> _values = {};
  FeatureVersion record(
    EngineeringFeature f,
    String action, {
    String branchId = 'main',
  }) {
    final list = _values[f.id] ??= [],
        v = FeatureVersion(
          list.length + 1,
          f,
          action,
          DateTime.now(),
          branchId,
        );
    list.add(v);
    return v;
  }

  List<FeatureVersion> get all =>
      List.unmodifiable(_values.values.expand((v) => v));
  EngineeringFeature replay(String id, int sequence) =>
      _values[id]!.firstWhere((v) => v.sequence == sequence).feature;
}
