import '../../cad_kernel/models/kernel_models.dart';
import '../engine/feature_engine.dart';
import '../models/feature_models.dart';

class FeatureApi {
  const FeatureApi(this.engine);
  final FeatureEngine engine;
  Future<FeatureResult> extrude(
    ShapeHandle profile, {
    required double distance,
  }) =>
      engine.execute(CadFeatureKind.extrude, [profile], {'distance': distance});
  Future<FeatureResult> revolve(
    ShapeHandle profile,
    ShapeHandle axis, {
    required double angle,
  }) =>
      engine.execute(CadFeatureKind.revolve, [profile, axis], {'angle': angle});
  Future<FeatureResult> sweep(ShapeHandle profile, ShapeHandle path) =>
      engine.execute(CadFeatureKind.sweep, [profile, path], const {});
  Future<FeatureResult> loft(List<ShapeHandle> profiles) {
    if (profiles.length < 2) {
      throw ArgumentError('Loft requires at least two profiles');
    }
    return engine.execute(CadFeatureKind.loft, profiles, const {});
  }

  Future<FeatureResult> union(List<ShapeHandle> shapes) =>
      _boolean(CadFeatureKind.booleanUnion, shapes);
  Future<FeatureResult> subtract(ShapeHandle target, ShapeHandle tool) =>
      _boolean(CadFeatureKind.booleanSubtract, [target, tool]);
  Future<FeatureResult> intersect(List<ShapeHandle> shapes) =>
      _boolean(CadFeatureKind.booleanIntersect, shapes);
  Future<FeatureResult> _boolean(
    CadFeatureKind kind,
    List<ShapeHandle> shapes,
  ) {
    if (shapes.length < 2 || shapes.any((e) => e.type != CADShapeType.solid)) {
      throw ArgumentError('Boolean requires at least two solids');
    }
    return engine.execute(kind, shapes, const {});
  }

  Future<FeatureResult> offset(ShapeHandle shape, double distance) =>
      engine.execute(CadFeatureKind.offset, [shape], {'distance': distance});
  Future<FeatureResult> shell(ShapeHandle solid, double thickness) =>
      engine.execute(CadFeatureKind.shell, [solid], {'thickness': thickness});
  Future<FeatureResult> draft(ShapeHandle shape, double angle) =>
      engine.execute(CadFeatureKind.draft, [shape], {'angle': angle});
  Future<FeatureResult> mirror(ShapeHandle shape, ShapeHandle plane) =>
      engine.execute(CadFeatureKind.mirror, [shape, plane], const {});
  Future<FeatureResult> linearPattern(
    ShapeHandle shape, {
    required int count,
    required double spacing,
  }) => engine.execute(
    CadFeatureKind.linearPattern,
    [shape],
    {'count': count, 'spacing': spacing},
  );
  Future<FeatureResult> circularPattern(
    ShapeHandle shape,
    ShapeHandle axis, {
    required int count,
    required double angle,
  }) => engine.execute(
    CadFeatureKind.circularPattern,
    [shape, axis],
    {'count': count, 'angle': angle},
  );
}
