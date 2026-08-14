import 'dart:io';
import '../../adaptive_studio/api/adaptive_studio_api.dart';
import '../../alignment_engine/api/alignment_api.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../engineering_intelligence/api/engineering_intelligence_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../geometric_recognition/api/recognition_api.dart';
import '../../interactive_reverse/api/interactive_reverse_api.dart';
import '../../live_validation/api/live_validation_api.dart';
import '../../reference_geometry/api/reference_api.dart';
import '../../reverse_session/api/reverse_session_api.dart';
import '../../reverse_workflow/api/reverse_workflow_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/platform_certification_api.dart';
import '../engine/platform_certification_engine.dart';
import '../repository/platform_certification_repository.dart';

class PlatformCertificationFactory {
  const PlatformCertificationFactory();
  PlatformCertificationApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    RecognitionApi? recognition,
    ReferenceApi? references,
    AlignmentApi? alignments,
    LiveValidationApi? validation,
    ReverseWorkflowApi? workflows,
    AdaptiveStudioApi? studio,
    InteractiveReverseApi? interactive,
    SketchEngineApi? sketches,
    ConstraintApi? constraints,
    FeatureModelingApi? features,
    EngineeringIntelligenceApi? intelligence,
    ReverseSessionApi? sessions,
  }) => PlatformCertificationApi(
    PlatformCertificationEngine(
      repository: PlatformCertificationRepository(projectDirectory),
    ),
  );
}
