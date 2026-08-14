import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../extrude_feature/api/extrude_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../../revolve_feature/api/revolve_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_editor/api/sketch_editor_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/transition_api.dart';
import '../engine/transition_engine.dart';
import '../repository/transition_repository.dart';

class TransitionFactory {
  const TransitionFactory();
  TransitionApi create({
    required Directory projectDirectory,
    required String projectId,
    required GeometryKernelAPI kernel,
    required ProfileRecognitionApi profiles,
    required FeatureModelingApi featurePlatform,
    SketchEngineApi? sketch,
    ConstraintApi? constraints,
    SketchEditorApi? editor,
    ExtrudeApi? extrudes,
    RevolveApi? revolves,
  }) => TransitionApi(
    TransitionEngine(
      projectId: projectId,
      kernel: kernel,
      profiles: profiles,
      platformApi: featurePlatform,
      repository: TransitionRepository(projectDirectory),
    ),
  );
}
