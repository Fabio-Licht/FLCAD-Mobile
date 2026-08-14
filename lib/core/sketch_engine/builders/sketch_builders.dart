import '../engine/sketch_engine.dart';
import '../entities/sketch_entities.dart';
import '../models/sketch_models.dart';

abstract class SketchEntityBuilder<T extends SketchEntity> {
  const SketchEntityBuilder(this.engine);
  final SketchEngine engine;
  T commit(T Function() create) => engine.transaction(
    runtimeType.toString(),
    () => engine.addEntity(create()),
  );
}

class PointBuilder extends SketchEntityBuilder<SketchPoint> {
  const PointBuilder(super.engine);
  SketchPoint build(SketchVector p) => commit(() => SketchPoint(p));
}

class LineBuilder extends SketchEntityBuilder<SketchLine> {
  const LineBuilder(super.engine);
  SketchLine build(SketchVector a, SketchVector b) =>
      commit(() => SketchLine(a, b));
}

class CircleBuilder extends SketchEntityBuilder<SketchCircle> {
  const CircleBuilder(super.engine);
  SketchCircle build(SketchVector c, double r) {
    if (r <= 0) throw ArgumentError.value(r, 'radius');
    return commit(() => SketchCircle(c, r));
  }
}

class ArcBuilder extends SketchEntityBuilder<SketchArc> {
  const ArcBuilder(super.engine);
  SketchArc build(SketchVector c, double r, double start, double end) {
    if (r <= 0) throw ArgumentError.value(r, 'radius');
    return commit(() => SketchArc(c, r, start, end));
  }
}

class SplineBuilder extends SketchEntityBuilder<SketchSpline> {
  const SplineBuilder(super.engine);
  SketchSpline build(List<SketchVector> points) {
    if (points.length < 2) {
      throw ArgumentError('A parametric spline needs at least two points');
    }
    return commit(() => SketchSpline(points));
  }
}

class EllipseBuilder extends SketchEntityBuilder<SketchEllipse> {
  const EllipseBuilder(super.engine);
  SketchEllipse build(SketchVector c, double rx, double ry) {
    if (rx <= 0 || ry <= 0) {
      throw ArgumentError('Ellipse radii must be positive');
    }
    return commit(() => SketchEllipse(c, rx, ry));
  }
}

class ConstructionBuilder extends SketchEntityBuilder<ConstructionGeometry> {
  const ConstructionBuilder(super.engine);
  ConstructionGeometry build(Map<String, dynamic> parameters) =>
      commit(() => ConstructionGeometry(parameters));
}

class ReferenceBuilder extends SketchEntityBuilder<ReferenceGeometry> {
  const ReferenceBuilder(super.engine);
  ReferenceGeometry build(Map<String, dynamic> parameters) =>
      commit(() => ReferenceGeometry(parameters));
}

class SketchBuilders {
  SketchBuilders(SketchEngine engine)
    : point = PointBuilder(engine),
      line = LineBuilder(engine),
      circle = CircleBuilder(engine),
      arc = ArcBuilder(engine),
      spline = SplineBuilder(engine),
      ellipse = EllipseBuilder(engine),
      construction = ConstructionBuilder(engine),
      reference = ReferenceBuilder(engine);
  final PointBuilder point;
  final LineBuilder line;
  final CircleBuilder circle;
  final ArcBuilder arc;
  final SplineBuilder spline;
  final EllipseBuilder ellipse;
  final ConstructionBuilder construction;
  final ReferenceBuilder reference;
}
