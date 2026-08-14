import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_editor/api/sketch_editor_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/extrude_api.dart';
import '../engine/extrude_engine.dart';
import '../repository/extrude_repository.dart';

class ExtrudeFactory {
  const ExtrudeFactory();
  ExtrudeApi create({
    required Directory projectDirectory,
    required String projectId,
    required GeometryKernelAPI kernel,
    required ProfileRecognitionApi profiles,
    required FeatureModelingApi featurePlatform,
    SketchEngineApi? sketch,
    ConstraintApi? constraints,
    SketchEditorApi? editor,
  }) => ExtrudeApi(
    ExtrudeEngine(
      projectId: projectId,
      kernel: kernel,
      profiles: profiles,
      platformApi: featurePlatform,
      repository: ExtrudeRepository(projectDirectory),
    ),
  );
}
