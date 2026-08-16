// ignore_for_file: curly_braces_in_flow_control_structures
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../api/import_export_api.dart';
import '../repository/import_export_repository.dart';
import '../validation/export_validation.dart';

class ExportEngine {
  ExportEngine({
    required this.kernel,
    required this.repository,
    this.validation = const ExportValidation(),
  });
  final GeometryKernelAPI kernel;
  final ImportExportRepository repository;
  final ExportValidation validation;
  double progress = 0;
  Future<CadExportResult> execute(CadExportRequest request) async {
    progress = .1;
    validation.validateRequest(request);
    if (kernel is! InterchangeGeometryKernelAPI)
      throw StateError('Active Geometry Kernel does not expose CAD export');
    final interchange = kernel as InterchangeGeometryKernelAPI;
    final diagnostics = await interchange.diagnose(request.shape);
    validation.validateDiagnostics(diagnostics);
    progress = .4;
    if (request.format == CadExportFormat.step ||
        request.format == CadExportFormat.iges) {
      await interchange.exportFile(
        request.shape,
        request.destination.path,
        request.format == CadExportFormat.step
            ? KernelExchangeFormat.step
            : KernelExchangeFormat.iges,
        onProgress: (_) {},
      );
    } else if (request.format == CadExportFormat.stl) {
      final result = await interchange.mesh(
        request.shape,
        outputPath: request.destination.path,
        deflection: .1,
      );
      if (result.vertexCount == 0 || result.triangleCount == 0)
        throw StateError('Geometry Kernel produced an empty STL mesh');
    } else {
      throw UnsupportedError(
        'OBJ export is not exposed by the official Geometry Kernel',
      );
    }
    if (!await request.destination.exists() ||
        await request.destination.length() == 0)
      throw StateError('Geometry Kernel did not create a valid output file');
    progress = .85;
    final registered = await repository.registerExport(request);
    final result = CadExportResult(
      destination: request.destination.path,
      registeredPath: registered.path,
      format: request.format,
      validation: diagnostics
          .map((e) => '${e.severity}:${e.code}:${e.message}')
          .toList(),
    );
    await repository.recordExport(request.projectDirectory, result);
    progress = 1;
    return result;
  }
}
