import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../../transition_features/api/transition_api.dart';
import '../api/reference_api.dart';
import '../engine/reference_engine.dart';
import '../repository/reference_repository.dart';

class ReferenceFactory {
  const ReferenceFactory();
  ReferenceApi create({
    required Directory projectDirectory,
    required String projectId,
    required GeometryKernelAPI kernel,
    SketchEngineApi? sketch,
    ProfileRecognitionApi? profiles,
    FeatureModelingApi? features,
    TransitionApi? transitions,
  }) => ReferenceApi(
    ReferenceEngine(
      projectId: projectId,
      kernel: kernel,
      repository: ReferenceRepository(projectDirectory),
    ),
  );
}
