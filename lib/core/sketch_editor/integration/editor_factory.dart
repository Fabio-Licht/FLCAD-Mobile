import 'dart:io';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/sketch_editor_api.dart';
import '../engine/sketch_editor_engine.dart';
import '../repository/editor_repository.dart';

class SketchEditorFactory {
  const SketchEditorFactory();
  SketchEditorApi create({
    required Directory projectDirectory,
    required SketchEngineApi sketch,
    required ConstraintApi constraints,
  }) => SketchEditorApi(
    SketchEditorEngine(
      sketch: sketch,
      constraints: constraints,
      repository: EditorRepository(projectDirectory),
    ),
  );
}
