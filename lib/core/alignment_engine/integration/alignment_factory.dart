import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../feature_modeling/api/feature_modeling_api.dart';
import '../../geometric_recognition/api/recognition_api.dart';
import '../../reference_geometry/api/reference_api.dart';
import '../../transition_features/api/transition_api.dart';
import '../api/alignment_api.dart';
import '../engine/alignment_engine.dart';
import '../repository/alignment_repository.dart';

class AlignmentFactory {
  const AlignmentFactory();
  AlignmentApi create({
    required Directory projectDirectory,
    required String projectId,
    required GeometryKernelAPI kernel,
    ReferenceApi? references,
    RecognitionApi? recognition,
    FeatureModelingApi? features,
    TransitionApi? transitions,
  }) => AlignmentApi(
    AlignmentEngine(
      projectId: projectId,
      kernel: kernel,
      repository: AlignmentRepository(projectDirectory),
    ),
  );
}
