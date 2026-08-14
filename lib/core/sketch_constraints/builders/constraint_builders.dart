import '../engine/constraint_engine.dart';
import '../models/constraint_models.dart';

class ConstraintBuilder {
  const ConstraintBuilder(this.engine, this.type);
  final ConstraintEngine engine;
  final SketchConstraintType type;
  SketchConstraint build(
    List<String> references, {
    double? value,
    int priority = 0,
    Map<String, dynamic> metadata = const {},
  }) => engine.transaction(
    'create ${type.name}',
    () => engine.add(
      SketchConstraint(
        type: type,
        references: references,
        value: value,
        priority: priority,
        metadata: metadata,
      ),
    ),
  );
}

class ConstraintBuilders {
  ConstraintBuilders(this.engine);
  final ConstraintEngine engine;
  ConstraintBuilder of(SketchConstraintType type) =>
      ConstraintBuilder(engine, type);
  ConstraintBuilder get coincident => of(SketchConstraintType.coincident);
  ConstraintBuilder get horizontal => of(SketchConstraintType.horizontal);
  ConstraintBuilder get vertical => of(SketchConstraintType.vertical);
  ConstraintBuilder get parallel => of(SketchConstraintType.parallel);
  ConstraintBuilder get perpendicular => of(SketchConstraintType.perpendicular);
  ConstraintBuilder get equal => of(SketchConstraintType.equal);
  ConstraintBuilder get tangent => of(SketchConstraintType.tangent);
  ConstraintBuilder get distance => of(SketchConstraintType.distance);
  ConstraintBuilder get radius => of(SketchConstraintType.radius);
  ConstraintBuilder get diameter => of(SketchConstraintType.diameter);
  ConstraintBuilder get angle => of(SketchConstraintType.angle);
  ConstraintBuilder get offset => of(SketchConstraintType.offset);
}
