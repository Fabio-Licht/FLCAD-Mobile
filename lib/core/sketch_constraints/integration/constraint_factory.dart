import 'dart:io';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/constraint_api.dart';
import '../engine/constraint_engine.dart';
import '../repository/constraint_repository.dart';

class ConstraintFactory {
  const ConstraintFactory();
  ConstraintApi create({
    required Directory projectDirectory,
    required SketchEngineApi sketch,
  }) => ConstraintApi(
    ConstraintEngine(
      sketch: sketch,
      repository: ConstraintRepository(projectDirectory),
    ),
  );
}
