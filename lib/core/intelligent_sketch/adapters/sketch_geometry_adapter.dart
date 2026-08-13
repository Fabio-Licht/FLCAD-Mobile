import '../../smart_regions/models/geometry.dart';
import '../models/sketch_context.dart';

abstract interface class SketchGeometryAdapter {
  SketchContextKind get kind;
  Future<String> fingerprint(String sourceId);
  Future<SketchAnchor> project(Vec3 point, String sourceId);
  Future<Vec3> normalAt(SketchAnchor anchor);
}

abstract interface class SurfaceSketchAdapter
    implements SketchGeometryAdapter {}

abstract interface class HybridGeometryKernel {
  Future<SketchAnchor> transfer(
    SketchAnchor anchor,
    SketchGeometryContext target,
  );
}
