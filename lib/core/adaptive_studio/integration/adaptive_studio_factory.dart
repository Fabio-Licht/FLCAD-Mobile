import 'dart:io';
import '../../alignment_engine/api/alignment_api.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../engineering_intelligence/api/engineering_intelligence_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../geometric_recognition/api/recognition_api.dart';
import '../../live_validation/api/live_validation_api.dart';
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../../reference_geometry/api/reference_api.dart';
import '../../reverse_workflow/api/reverse_workflow_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/adaptive_studio_api.dart';
import '../repository/adaptive_studio_repository.dart';
import '../workspace/adaptive_workspace_engine.dart';

class AdaptiveStudioFactory {
  const AdaptiveStudioFactory();
  AdaptiveStudioApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    ReverseWorkflowApi? workflows,
    RecognitionApi? recognition,
    ReferenceApi? references,
    AlignmentApi? alignments,
    LiveValidationApi? validation,
    EngineeringIntelligenceApi? intelligence,
    SketchEngineApi? sketches,
    ConstraintApi? constraints,
    ProfileRecognitionApi? profiles,
    FeatureModelingApi? features,
  }) => AdaptiveStudioApi(
    AdaptiveWorkspaceEngine(
      repository: AdaptiveStudioRepository(projectDirectory),
    ),
  );
}
