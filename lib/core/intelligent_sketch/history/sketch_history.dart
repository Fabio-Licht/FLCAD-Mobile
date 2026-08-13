import '../models/sketch.dart';

class SketchVersion {
  const SketchVersion(this.sequence, this.sketch, this.action, this.timestamp);
  final int sequence;
  final IntelligentSketch sketch;
  final String action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'sketchId': sketch.id,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
  };
}

class SketchHistory {
  final Map<String, List<SketchVersion>> _versions = {};
  SketchVersion record(IntelligentSketch sketch, String action) {
    final list = _versions[sketch.id] ??= [];
    final version = SketchVersion(
      list.length + 1,
      sketch,
      action,
      DateTime.now(),
    );
    list.add(version);
    return version;
  }

  List<SketchVersion> versions(String id) =>
      List.unmodifiable(_versions[id] ?? const []);
  List<SketchVersion> get all =>
      List.unmodifiable(_versions.values.expand((e) => e));
  IntelligentSketch replay(String id, int sequence) =>
      versions(id).firstWhere((v) => v.sequence == sequence).sketch;
  IntelligentSketch? undo(String id) {
    final values = versions(id);
    return values.length < 2 ? null : values[values.length - 2].sketch;
  }
}
