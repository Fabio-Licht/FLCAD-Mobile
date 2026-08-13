import 'dart:convert';
import 'dart:io';

import '../domain/pipeline_exception.dart';
import '../services/image_quality_service.dart';
import 'pipeline_context.dart';
import 'pipeline_step.dart';

class CaptureValidationStep implements PipelineStep {
  @override
  String get id => '01_capture_validation';
  @override
  String get name => 'Validação das Capturas';
  @override
  Future<void> execute(PipelineContext context) async {
    final valid = <String>[];
    for (final imagePath in context.imagePaths) {
      if (await File(imagePath).exists()) valid.add(imagePath);
    }
    if (valid.length < 3) {
      throw const PipelineException(
        'São necessárias pelo menos 3 imagens válidas',
      );
    }
    context.values['validImages'] = valid;
  }
}

class ImageQualityAnalysisStep implements PipelineStep {
  ImageQualityAnalysisStep({ImageQualityService? service})
    : _service = service ?? const AlphaImageQualityService();
  final ImageQualityService _service;
  @override
  String get id => '02_image_quality';
  @override
  String get name => 'Análise de Qualidade';
  @override
  Future<void> execute(PipelineContext context) async {
    final images =
        (context.values['validImages'] as List?)?.cast<String>() ??
        context.imagePaths;
    final analyses = await _service.analyze(images);
    context.values['quality'] = analyses.map((item) => item.toJson()).toList();
    context.values['acceptedImages'] = analyses
        .where((item) => item.score >= 40)
        .map((item) => item.path)
        .toList();
    context.values['discardedImages'] = analyses
        .where((item) => item.score < 40)
        .map((item) => item.path)
        .toList();
  }
}

abstract class ArtifactStep implements PipelineStep {
  const ArtifactStep(this.id, this.name, this.folder, this.fileName);
  @override
  final String id;
  @override
  final String name;
  final String folder;
  final String fileName;
  @override
  Future<void> execute(PipelineContext context) async {
    final directory = Directory('${context.cachePath}/$folder');
    await directory.create(recursive: true);
    await File('${directory.path}/$fileName').writeAsString(
      jsonEncode({
        'step': id,
        'projectId': context.projectId,
        'fingerprint': context.fingerprint,
        'generatedAt': DateTime.now().toIso8601String(),
      }),
      flush: true,
    );
  }
}

class BackgroundSegmentationStep extends ArtifactStep {
  const BackgroundSegmentationStep()
    : super(
        '03_background_segmentation',
        'Segmentação de Fundo',
        'Segmentation',
        'mask_manifest.json',
      );
}

class FeatureDetectionStep extends ArtifactStep {
  const FeatureDetectionStep()
    : super(
        '04_feature_detection',
        'Detecção de Features',
        'Features',
        'features.json',
      );
}

class FeatureMatchingStep extends ArtifactStep {
  const FeatureMatchingStep()
    : super(
        '05_feature_matching',
        'Correspondência de Features',
        'Matches',
        'matches.json',
      );
}

class CameraPoseEstimationStep extends ArtifactStep {
  const CameraPoseEstimationStep()
    : super('06_camera_pose', 'Estimativa de Poses', 'Sparse', 'cameras.json');
}

class SparsePointCloudStep extends ArtifactStep {
  const SparsePointCloudStep()
    : super('07_sparse_cloud', 'Nuvem Esparsa', 'Sparse', 'points.json');
}

class DensePointCloudStep extends ArtifactStep {
  const DensePointCloudStep()
    : super('08_dense_cloud', 'Nuvem Densa', 'Dense', 'points.json');
}

class MeshGenerationStep implements PipelineStep {
  @override
  String get id => '09_mesh_generation';
  @override
  String get name => 'Geração de Malha';
  @override
  Future<void> execute(PipelineContext context) async {
    final output = File('${context.projectPath}/Mesh/alpha_model.json');
    await output.parent.create(recursive: true);
    await output.writeAsString(
      jsonEncode({
        'format': 'flcad-alpha-mesh',
        'vertices': [
          [-1, -1, 0],
          [1, -1, 0],
          [1, 1, 0],
          [-1, 1, 0],
          [0, 0, 1.5],
        ],
        'faces': [
          [0, 1, 4],
          [1, 2, 4],
          [2, 3, 4],
          [3, 0, 4],
          [0, 1, 2],
          [0, 2, 3],
        ],
      }),
      flush: true,
    );
    context.values['resultPath'] = output.path;
  }
}

class MeshOptimizationStep extends ArtifactStep {
  const MeshOptimizationStep()
    : super(
        '10_mesh_optimization',
        'Otimização da Malha',
        'Mesh',
        'optimized.json',
      );
}

class TextureProjectionStep extends ArtifactStep {
  const TextureProjectionStep()
    : super(
        '11_texture_projection',
        'Projeção de Textura',
        'Mesh',
        'texture.json',
      );
}

class ReconstructionReportStep implements PipelineStep {
  @override
  String get id => '12_reconstruction_report';
  @override
  String get name => 'Relatório de Reconstrução';
  @override
  Future<void> execute(PipelineContext context) async {
    final quality =
        (context.values['quality'] as List?)?.cast<Map>() ?? const [];
    final scores = quality.map((item) => item['score'] as int).toList();
    final average = scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a + b) / scores.length;
    final report = File('${context.reconstructionPath}/reconstruction.json');
    final startedAt = DateTime.tryParse(
      context.values['pipelineStartedAt'] as String? ?? '',
    );
    await report.parent.create(recursive: true);
    await report.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'projectId': context.projectId,
        'generatedAt': DateTime.now().toIso8601String(),
        'processingTimeMs': startedAt == null
            ? null
            : DateTime.now().difference(startedAt).inMilliseconds,
        'photosUsed':
            (context.values['acceptedImages'] as List?)?.length ??
            context.imagePaths.length,
        'photosDiscarded':
            (context.values['discardedImages'] as List?)?.length ?? 0,
        'averageQualityScore': average,
        'errors': const [],
        'pipeline': const [
          'captureValidation',
          'imageQuality',
          'backgroundSegmentation',
          'featureDetection',
          'featureMatching',
          'cameraPose',
          'sparseCloud',
          'denseCloud',
          'meshGeneration',
          'meshOptimization',
          'textureProjection',
          'report',
        ],
        'statistics': {'inputPhotos': context.imagePaths.length},
        'resultPath': context.values['resultPath'],
      }),
      flush: true,
    );
  }
}

List<PipelineStep> createStandardPipelineSteps() => [
  CaptureValidationStep(),
  ImageQualityAnalysisStep(),
  const BackgroundSegmentationStep(),
  const FeatureDetectionStep(),
  const FeatureMatchingStep(),
  const CameraPoseEstimationStep(),
  const SparsePointCloudStep(),
  const DensePointCloudStep(),
  MeshGenerationStep(),
  const MeshOptimizationStep(),
  const TextureProjectionStep(),
  ReconstructionReportStep(),
];
