import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../../mesh_foundation/models/mesh_models.dart';
import '../../surface_recognition/models/surface_recognition_models.dart';
import '../../utils/id_generator.dart';
import '../advisor/surface_fit_advisor.dart';
import '../fitters/primitive_surface_fitters.dart';
import '../integration/surface_fitting_integration.dart';
import '../models/surface_fitting_models.dart';
import '../repository/surface_fitting_repository.dart';
import '../runtime/surface_fitting_runtime.dart';
import '../validation/surface_fit_validation.dart';

class SurfaceFittingEngine {
  SurfaceFittingEngine({
    required this.kernel,
    required this.repository,
    this.integration,
    List<ProfessionalSurfaceFitter>? fitters,
  }) : fitters =
           fitters ??
           const [
             PlaneSurfaceFitter(),
             CylinderSurfaceFitter(),
             ConeSurfaceFitter(),
             SphereSurfaceFitter(),
             TorusSurfaceFitter(),
           ];
  final GeometryKernelAPI kernel;
  final SurfaceFittingRepository repository;
  final SurfaceFittingIntegration? integration;
  final List<ProfessionalSurfaceFitter> fitters;
  final validation = const SurfaceFitValidation();
  final advisor = const SurfaceFitAdvisor();

  Future<SurfaceFittingReport> fit({
    required MeshEntity mesh,
    required SurfaceRecognitionReport recognition,
    required String projectId,
  }) async {
    if (kernel is! MeshGeometryKernelAPI) {
      throw StateError(
        'Active GeometryKernelAPI does not expose native mesh inspection',
      );
    }
    if (recognition.meshId != mesh.id) {
      throw ArgumentError('Recognition report belongs to another mesh');
    }
    await SurfaceFittingRuntime.instance.initialize();
    final watch = Stopwatch()..start(),
        geometry = await (kernel as MeshGeometryKernelAPI).inspectMesh(
          mesh.kernelHandle,
        ),
        data = MeshSurfaceData.fromKernel(geometry),
        surfaces = <SurfaceEntity>[];
    final transaction = KernelTransaction(
      'surface-fit-transaction:${IdGenerator.generate()}',
      projectId,
      kernel.descriptor.id,
      DateTime.now().toUtc(),
      TransactionStatus.active,
      const [],
    );
    await kernel.begin(transaction);
    try {
      for (final region in recognition.classifications) {
        final fitter = fitters.where((f) => f.type == region.type).firstOrNull;
        if (fitter == null) {
          surfaces.add(_notApplicable(region));
          continue;
        }
        final points = region.region.vertexIndices
            .map((i) => data.vertices[i])
            .toList();
        final candidate = fitter.fit(region, points),
            errors = validation.validateCandidate(candidate);
        if (errors.isNotEmpty || !candidate.valid) {
          surfaces.add(_rejected(region, candidate));
          continue;
        }
        final id = 'surface:${IdGenerator.generate()}';
        final handle = await kernel.create(
          _operation(candidate.type),
          candidate.parameters,
          persistentId: id,
          expectedType: CADShapeType.face,
          transaction: transaction,
        );
        final diagnostics = await kernel.validate(handle, const {
          'topology',
          'geometry',
        });
        if (diagnostics.isNotEmpty) {
          throw StateError(
            'OpenCascade rejected $id: ${diagnostics.join('; ')}',
          );
        }
        surfaces.add(
          SurfaceEntity(
            id: id,
            recognitionRegionId: region.region.id,
            primitiveType: region.type,
            handle: handle,
            bounds: region.region.bounds,
            area: region.region.area,
            parameters: candidate.parameters,
            residuals: candidate.residuals,
            confidence: candidate.confidence,
            health: _health(candidate.confidence),
            timestamp: DateTime.now().toUtc(),
            status: SurfaceFitStatus.accepted,
          ),
        );
      }
      await kernel.commit(transaction);
    } catch (_) {
      await kernel.rollback(transaction);
      rethrow;
    }
    watch.stop();
    final fitted = surfaces
            .where((e) => e.status == SurfaceFitStatus.accepted)
            .toList(),
        distribution = <PrimitiveType, int>{};
    for (final surface in fitted) {
      distribution[surface.primitiveType] =
          (distribution[surface.primitiveType] ?? 0) + 1;
    }
    double average(double Function(SurfaceEntity e) select) => fitted.isEmpty
        ? 0
        : fitted.fold<double>(0, (s, e) => s + select(e)) / fitted.length;
    final analytics = SurfaceFittingAnalytics(
      elapsed: watch.elapsed,
      distribution: distribution,
      averageRms: average((e) => e.residuals.rms),
      averageResidual: average((e) => e.residuals.mean),
      averageConfidence: average((e) => e.confidence),
      accepted: fitted.length,
      rejected: surfaces.length - fitted.length,
    );
    final report = SurfaceFittingReport(
      id: 'surface-fit-report:${IdGenerator.generate()}',
      recognitionReportId: recognition.id,
      surfaces: surfaces,
      analytics: analytics,
      advice: advisor.advise(surfaces),
      createdAt: DateTime.now().toUtc(),
    );
    final reportErrors = validation.validateReport(report);
    if (reportErrors.isNotEmpty) throw StateError(reportErrors.join('; '));
    repository.save(report);
    integration?.onSurfaceFittingCompleted(report);
    return report;
  }

  String _operation(PrimitiveType type) => switch (type) {
    PrimitiveType.plane => 'GENERATE PLANE',
    PrimitiveType.cylinder => 'GENERATE CYLINDER',
    PrimitiveType.cone => 'GENERATE CONE',
    PrimitiveType.sphere => 'GENERATE SPHERE',
    PrimitiveType.torus => 'GENERATE TORUS',
    _ => throw UnsupportedError('No native surface operation for ${type.name}'),
  };
  SurfaceFitHealth _health(double c) => switch (c) {
    >= .9 => SurfaceFitHealth.excellent,
    >= .75 => SurfaceFitHealth.good,
    >= .55 => SurfaceFitHealth.medium,
    >= .45 => SurfaceFitHealth.low,
    _ => SurfaceFitHealth.rejected,
  };
  SurfaceEntity _notApplicable(SurfaceClassification region) => SurfaceEntity(
    id: 'surface-fit:${IdGenerator.generate()}',
    recognitionRegionId: region.region.id,
    primitiveType: region.type,
    handle: null,
    bounds: region.region.bounds,
    area: region.region.area,
    parameters: const {},
    residuals: const ResidualStatistics(
      values: [],
      rms: double.infinity,
      maximum: double.infinity,
      mean: double.infinity,
      standardDeviation: double.infinity,
      distribution: {},
    ),
    confidence: 0,
    health: SurfaceFitHealth.rejected,
    timestamp: DateTime.now().toUtc(),
    status: SurfaceFitStatus.notApplicable,
  );
  SurfaceEntity _rejected(
    SurfaceClassification region,
    SurfaceFitCandidate candidate,
  ) => SurfaceEntity(
    id: 'surface-fit:${IdGenerator.generate()}',
    recognitionRegionId: region.region.id,
    primitiveType: region.type,
    handle: null,
    bounds: region.region.bounds,
    area: region.region.area,
    parameters: candidate.parameters,
    residuals: candidate.residuals,
    confidence: candidate.confidence,
    health: SurfaceFitHealth.rejected,
    timestamp: DateTime.now().toUtc(),
    status: SurfaceFitStatus.rejected,
  );
}
