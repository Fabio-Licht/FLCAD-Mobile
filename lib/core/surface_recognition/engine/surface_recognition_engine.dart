import '../../cad_kernel/io/kernel_io_models.dart';
import '../../mesh_foundation/models/mesh_models.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../../utils/id_generator.dart';
import '../advisor/recognition_advisor.dart';
import '../classification/primitive_classifier.dart';
import '../integration/surface_recognition_integration.dart';
import '../models/surface_recognition_models.dart';
import '../repository/surface_recognition_repository.dart';
import '../runtime/surface_recognition_runtime.dart';
import '../segmentation/region_growing.dart';

class SurfaceRecognitionEngine {
  SurfaceRecognitionEngine({
    required this.kernel,
    required this.repository,
    this.integration,
    this.settings = const SurfaceRecognitionSettings(),
  });
  final MeshGeometryKernelAPI kernel;
  final SurfaceRecognitionRepository repository;
  final SurfaceRecognitionIntegration? integration;
  final SurfaceRecognitionSettings settings;
  final segmentation = const ProfessionalRegionGrowing();
  final classifier = const PrimitiveClassifier();
  final advisor = const SurfaceRecognitionAdvisor();

  Future<SurfaceRecognitionReport> recognize(MeshEntity mesh) async {
    if (mesh.state != MeshState.open) {
      throw StateError('Mesh is not open: ${mesh.id}');
    }
    await SurfaceRecognitionRuntime.instance.initialize();
    final watch = Stopwatch()..start();
    final native = await kernel.inspectMesh(mesh.kernelHandle);
    final data = MeshSurfaceData.fromKernel(native);
    if (data.vertices.length != mesh.vertexCount ||
        data.triangles.length != mesh.triangleCount) {
      throw StateError('Kernel mesh inspection count mismatch');
    }
    final segmented = segmentation.segment(
      data,
      mesh.checksum,
      settings: settings,
    );
    final classifications = [
      for (final region in segmented.regions) classifier.classify(region, data),
    ];
    watch.stop();
    final total = classifications.fold<double>(0, (s, c) => s + c.region.area);
    final unknown = classifications
        .where((c) => c.type.name == 'unknown')
        .fold<double>(0, (s, c) => s + c.region.area);
    final distribution = <PrimitiveType, int>{};
    for (final c in classifications) {
      distribution[c.type] = (distribution[c.type] ?? 0) + 1;
    }
    final analytics = RecognitionAnalytics(
      elapsed: watch.elapsed,
      totalArea: total,
      recognizedArea: total - unknown,
      unknownArea: unknown,
      averageConfidence: classifications.isEmpty
          ? 0
          : classifications.fold<double>(0, (s, c) => s + c.confidence) /
                classifications.length,
      distribution: distribution,
    );
    final report = SurfaceRecognitionReport(
      id: 'surface-recognition:${IdGenerator.generate()}',
      meshId: mesh.id,
      classifications: classifications,
      graph: segmented.graph,
      analytics: analytics,
      advice: advisor.advise(classifications),
      createdAt: DateTime.now().toUtc(),
    );
    repository.save(report);
    integration?.onRecognitionCompleted(report);
    return report;
  }
}
