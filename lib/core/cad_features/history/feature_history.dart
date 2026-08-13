import '../models/feature_models.dart';

enum FeatureHistoryAction {
  create,
  rebuild,
  fail,
  unavailable,
  healing,
  validation,
}

class FeatureHistoryEntry {
  const FeatureHistoryEntry(
    this.action,
    this.feature,
    this.timestamp,
    this.metadata,
  );
  final FeatureHistoryAction action;
  final CadFeature feature;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

class FeatureHistory {
  final List<FeatureHistoryEntry> _entries = [];
  List<FeatureHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(
    FeatureHistoryAction action,
    CadFeature feature, {
    Map<String, dynamic> metadata = const {},
  }) => _entries.add(
    FeatureHistoryEntry(action, feature, DateTime.now(), metadata),
  );
  List<CadFeature> replay() => _entries
      .where(
        (e) =>
            e.action == FeatureHistoryAction.create ||
            e.action == FeatureHistoryAction.rebuild,
      )
      .map((e) => e.feature)
      .toList();
}
