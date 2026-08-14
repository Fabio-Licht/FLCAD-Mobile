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
import '../../reverse_workflow/api/reverse_workflow_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/reverse_session_api.dart';
import '../engine/reverse_session_engine.dart';
import '../repository/reverse_session_repository.dart';

class ReverseSessionFactory {
  const ReverseSessionFactory();
  ReverseSessionApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    ReverseWorkflowApi? workflows,
    AdaptiveStudioApi? studio,
    InteractiveReverseApi? interactive,
    RecognitionApi? recognition,
    ReferenceApi? references,
    AlignmentApi? alignments,
    LiveValidationApi? validation,
    EngineeringIntelligenceApi? intelligence,
    SketchEngineApi? sketches,
    ConstraintApi? constraints,
    FeatureModelingApi? features,
  }) => ReverseSessionApi(
    ReverseSessionEngine(
      repository: ReverseSessionRepository(projectDirectory),
    ),
  );
}
