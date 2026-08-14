enum SketchSnapType {
  endpoint,
  midpoint,
  center,
  quadrant,
  intersection,
  perpendicular,
  parallel,
  tangent,
  nearest,
  origin,
  grid,
  reference,
}

class SketchSnapSettings {
  const SketchSnapSettings({
    this.enabled = const {
      SketchSnapType.endpoint,
      SketchSnapType.midpoint,
      SketchSnapType.center,
    },
    this.priority = const {},
  });
  final Set<SketchSnapType> enabled;
  final Map<SketchSnapType, int> priority;
  List<SketchSnapType> ordered() {
    final result = enabled.toList()
      ..sort((a, b) => (priority[b] ?? 0).compareTo(priority[a] ?? 0));
    return result;
  }
}
