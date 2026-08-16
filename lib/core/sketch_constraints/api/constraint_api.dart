import '../builders/constraint_builders.dart';
import '../diagnostics/constraint_diagnostics.dart';
import '../engine/constraint_engine.dart';
import '../models/constraint_models.dart';

class ConstraintApi {
  ConstraintApi(this.engine) : builders = ConstraintBuilders(engine);
  final ConstraintEngine engine;
  final ConstraintBuilders builders;
  List<SketchConstraint> get constraints =>
      List.unmodifiable(engine.constraints.values);
  Future<ConstraintSolveResult> solve({Iterable<String>? only}) =>
      engine.solve(only: only);
  Future<ConstraintSolveResult> rebuild() => engine.rebuild();
  Future<void> load() => engine.load();
  Future<void> persist() => engine.persist();
  void delete(String id) => engine.delete(id);
  void enable(String id) => engine.enable(id);
  void disable(String id) => engine.disable(id);
  void suppress(String id) => engine.suppress(id);
}
