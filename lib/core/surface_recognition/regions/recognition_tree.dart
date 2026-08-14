import '../models/surface_recognition_models.dart';

class RecognitionTreeItem {
  RecognitionTreeItem(this.classification);
  final SurfaceClassification classification;
  bool selected = false, highlighted = false;
  Map<String, dynamic> toJson() => {
    ...classification.toJson(),
    'selected': selected,
    'highlighted': highlighted,
  };
}

class RecognitionTree {
  RecognitionTree(Iterable<SurfaceClassification> values) {
    for (final value in values) {
      groups
          .putIfAbsent(value.type.name, () => [])
          .add(RecognitionTreeItem(value));
    }
  }
  final Map<String, List<RecognitionTreeItem>> groups = {};
  String? selectedRegionId;
  void select(String id) {
    var found = false;
    for (final item in groups.values.expand((e) => e)) {
      final selected = item.classification.region.id == id;
      item.selected = selected;
      item.highlighted = selected;
      found |= selected;
    }
    if (!found) throw StateError('Unknown recognition region: $id');
    selectedRegionId = id;
  }

  Map<String, dynamic> inspectSelected() {
    final item = groups.values
        .expand((e) => e)
        .where((e) => e.selected)
        .firstOrNull;
    return item?.classification.toJson() ?? const {};
  }

  Map<String, dynamic> toJson() => {
    'Recognition': groups.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    ),
  };
}
