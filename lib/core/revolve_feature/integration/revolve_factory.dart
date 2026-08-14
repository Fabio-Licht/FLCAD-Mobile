import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../extrude_feature/api/extrude_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_editor/api/sketch_editor_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/revolve_api.dart';
import '../engine/revolve_engine.dart';
import '../repository/revolve_repository.dart';

class RevolveFactory {
  const RevolveFactory();
  RevolveApi create({
    required Directory projectDirectory,
    required String projectId,
    required GeometryKernelAPI kernel,
    required ProfileRecognitionApi profiles,
    required FeatureModelingApi featurePlatform,
    SketchEngineApi? sketch,
    ConstraintApi? constraints,
    SketchEditorApi? editor,
    ExtrudeApi? extrudes,
  }) => RevolveApi(
    RevolveEngine(
      projectId: projectId,
      kernel: kernel,
      profiles: profiles,
      platformApi: featurePlatform,
      repository: RevolveRepository(projectDirectory),
    ),
  );
}
