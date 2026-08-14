import 'dart:io';
import '../../alignment_engine/api/alignment_api.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../geometric_recognition/api/recognition_api.dart';
import '../../reference_geometry/api/reference_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../../transition_features/api/transition_api.dart';
import '../api/live_validation_api.dart';
import '../engine/live_validation_engine.dart';
import '../repository/validation_repository.dart';

class LiveValidationFactory {
  const LiveValidationFactory();
  LiveValidationApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    RecognitionApi? recognition,
    ReferenceApi? references,
    AlignmentApi? alignments,
    SketchEngineApi? sketches,
    FeatureModelingApi? features,
    TransitionApi? transitions,
  }) => LiveValidationApi(
    LiveValidationEngine(
      kernel: kernel,
      repository: ValidationRepository(projectDirectory),
    ),
  );
}
