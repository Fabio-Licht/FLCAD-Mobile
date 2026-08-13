import '../builders/feature_builder.dart';
import '../engine/parametric_engineering_engine.dart';
import '../features/engineering_feature.dart';
import '../solids/engineering_solid.dart';
import '../timeline/engineering_timeline.dart';
import '../validators/engineering_validators.dart';

class ParametricApi {
  ParametricApi({ParametricEngineeringEngine? engine})
    : engine = engine ?? ParametricEngineeringEngine();
  final ParametricEngineeringEngine engine;
  Future<EngineeringFeature> createFeature(
    FeatureRecipe r, {
    String branch = 'main',
  }) => engine.createFeature(r, branch: branch);
  Future<EngineeringFeature> rebuild(
    EngineeringFeature f,
    Map<String, dynamic> p,
  ) => engine.rebuild(f, p);
  Future<EngineeringSolid> createSolid(
    String id,
    String name,
    List<EngineeringFeature> f,
  ) => engine.createSolid(id, name, f);
  ValidationReport validateFeature(EngineeringFeature f) =>
      engine.validateFeature(f);
  ValidationReport validateSolid(EngineeringSolid s) => engine.validateSolid(s);
  void createBranch(String id, TimelineBranch b) => engine.createBranch(id, b);
  List<EngineeringDecision> replay(String branch, {int? until}) =>
      engine.timeline.replay(branch, until: until);
}
