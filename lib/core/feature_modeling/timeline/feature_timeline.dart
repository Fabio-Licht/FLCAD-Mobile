import '../models/feature_models.dart';

class FeatureTimelineEntry {
  FeatureTimelineEntry(this.featureId, this.position)
    : state = FeatureExecutionState.pending;
  final String featureId;
  int position;
  FeatureExecutionState state;
  bool rollbackPoint = false;
}

class FeatureTimeline {
  final List<FeatureTimelineEntry> _entries = [];
  final Set<String> rebuildQueue = {};
  List<FeatureTimelineEntry> get entries => List.unmodifiable(_entries);
  void add(String id) {
    _entries.add(FeatureTimelineEntry(id, _entries.length));
  }

  void remove(String id) {
    _entries.removeWhere((e) => e.featureId == id);
    for (var i = 0; i < _entries.length; i++) {
      _entries[i].position = i;
    }
    rebuildQueue.remove(id);
  }

  void markDirty(Iterable<String> ids) {
    rebuildQueue.addAll(ids);
  }

  List<String> executionOrder([Iterable<String>? subset]) {
    final allowed = subset?.toSet();
    return _entries
        .where((e) => allowed == null || allowed.contains(e.featureId))
        .map((e) => e.featureId)
        .toList();
  }

  void rollbackAt(String id) {
    for (final e in _entries) {
      e.rollbackPoint = e.featureId == id;
    }
  }

  Map<String, dynamic> toJson() => {
    'entries': _entries
        .map(
          (e) => {
            'featureId': e.featureId,
            'position': e.position,
            'state': e.state.name,
            'rollbackPoint': e.rollbackPoint,
          },
        )
        .toList(),
    'rebuildQueue': rebuildQueue.toList(),
  };
}
