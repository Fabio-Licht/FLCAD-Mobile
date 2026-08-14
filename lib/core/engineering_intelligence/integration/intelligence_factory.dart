import 'dart:io';
import '../../alignment_engine/api/alignment_api.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../geometric_recognition/api/recognition_api.dart';
import '../../live_validation/api/live_validation_api.dart';
import '../../reference_geometry/api/reference_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/engineering_intelligence_api.dart';
import '../engine/engineering_intelligence_engine.dart';
import '../repository/intelligence_repository.dart';

class EngineeringIntelligenceFactory {
  const EngineeringIntelligenceFactory();
  EngineeringIntelligenceApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    RecognitionApi? recognition,
    ReferenceApi? references,
    AlignmentApi? alignments,
    LiveValidationApi? validation,
    SketchEngineApi? sketches,
    FeatureModelingApi? features,
    Object? engineeringBrain,
    Map<String, dynamic> projectMetadata = const {},
  }) => EngineeringIntelligenceApi(
    EngineeringIntelligenceEngine(
      kernel: kernel,
      repository: IntelligenceRepository(projectDirectory),
    ),
  );
}
