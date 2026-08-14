import 'dart:io';
import '../../alignment_engine/api/alignment_api.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../engineering_intelligence/api/engineering_intelligence_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../geometric_recognition/api/recognition_api.dart';
import '../../live_validation/api/live_validation_api.dart';
import '../../reference_geometry/api/reference_api.dart';
import '../../reverse_workflow/api/reverse_workflow_api.dart';
import '../../sketch_constraints/api/constraint_api.dart';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/interactive_reverse_api.dart';
import '../engine/interactive_reverse_engine.dart';
import '../repository/interactive_reverse_repository.dart';

class InteractiveReverseFactory {
  const InteractiveReverseFactory();
  InteractiveReverseApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    RecognitionApi? recognition,
    ReferenceApi? references,
    AlignmentApi? alignments,
    LiveValidationApi? validation,
    EngineeringIntelligenceApi? intelligence,
    ReverseWorkflowApi? workflows,
    SketchEngineApi? sketches,
    ConstraintApi? constraints,
    FeatureModelingApi? features,
  }) => InteractiveReverseApi(
    InteractiveReverseEngine(
      repository: InteractiveReverseRepository(projectDirectory),
    ),
  );
}
