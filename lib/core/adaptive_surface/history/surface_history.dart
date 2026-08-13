import '../models/adaptive_surface.dart';

class SurfaceVersion {
  const SurfaceVersion(
    this.sequence,
    this.surface,
    this.action,
    this.timestamp,
  );
  final int sequence;
  final AdaptiveSurface surface;
  final String action;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'surfaceId': surface.id,
    'action': action,
    'timestamp': timestamp.toIso8601String(),
  };
}

class SurfaceHistory {
  final Map<String, List<SurfaceVersion>> _values = {};
  SurfaceVersion record(AdaptiveSurface surface, String action) {
    final list = _values[surface.id] ??= [],
        value = SurfaceVersion(
          list.length + 1,
          surface,
          action,
          DateTime.now(),
        );
    list.add(value);
    return value;
  }

  List<SurfaceVersion> versions(String id) =>
      List.unmodifiable(_values[id] ?? const []);
  List<SurfaceVersion> get all =>
      List.unmodifiable(_values.values.expand((v) => v));
  AdaptiveSurface replay(String id, int sequence) =>
      versions(id).firstWhere((v) => v.sequence == sequence).surface;
}
