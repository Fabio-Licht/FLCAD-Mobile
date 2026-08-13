import '../adapters/sketch_geometry_adapter.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch_context.dart';

enum SurfaceContinuity { positional, tangent, curvature }

abstract interface class SurfaceDomain {
  String get id;
  SketchContextKind get kind;
}

abstract interface class SurfaceCurveProjector implements SurfaceSketchAdapter {
  Future<SketchEntity> projectEntity(SketchEntity entity, String surfaceId);
  Future<double> continuityAt(SketchAnchor anchor);
}
