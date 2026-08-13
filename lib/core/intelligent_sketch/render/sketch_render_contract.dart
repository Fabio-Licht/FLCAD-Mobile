import '../entities/sketch_entity.dart';

class SketchRenderDelta {
  const SketchRenderDelta({
    this.added = const [],
    this.updated = const [],
    this.removed = const [],
  });
  final List<SketchEntity> added, updated;
  final List<String> removed;
}

abstract interface class SketchRenderer {
  Future<void> initialize(String sketchId);
  Future<void> apply(SketchRenderDelta delta);
  Future<void> dispose();
}
