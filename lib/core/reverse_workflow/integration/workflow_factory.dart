import 'dart:io';
import '../../alignment_engine/api/alignment_api.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../engineering_intelligence/api/engineering_intelligence_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../geometric_recognition/api/recognition_api.dart';
import '../../live_validation/api/live_validation_api.dart';
import '../../profile_recognition/api/profile_recognition_api.dart';
import '../../reference_geometry/api/reference_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/reverse_workflow_api.dart';
import '../engine/reverse_workflow_engine.dart';
import '../repository/workflow_repository.dart';

class ReverseWorkflowFactory {
  const ReverseWorkflowFactory();
  ReverseWorkflowApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    RecognitionApi? recognition,
    ReferenceApi? references,
    AlignmentApi? alignments,
    LiveValidationApi? validation,
    EngineeringIntelligenceApi? intelligence,
    SketchEngineApi? sketches,
    ConstraintApi? constraints,
    ProfileRecognitionApi? profiles,
    FeatureModelingApi? features,
  }) => ReverseWorkflowApi(
    ReverseWorkflowEngine(repository: WorkflowRepository(projectDirectory)),
  );
}
