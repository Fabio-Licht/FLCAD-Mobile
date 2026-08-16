// ignore_for_file: curly_braces_in_flow_control_structures
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../api/import_export_api.dart';
import '../repository/import_export_repository.dart';
import '../validation/import_validation.dart';

class ImportEngine {
  ImportEngine({
    required this.kernel,
    required this.repository,
    this.validation = const ImportValidation(),
  });
  final GeometryKernelAPI kernel;
  final ImportExportRepository repository;
  final ImportValidation validation;
  double progress = 0;
  Future<ImportedCadDocument> execute(CadImportRequest request) async {
    progress = .05;
    await validation.validateFile(request);
    progress = .2;
    progress = .35;
    ImportedCadDocument document;
    if (request.format == CadImportFormat.stl) {
      if (kernel is! MeshGeometryKernelAPI)
        throw StateError(
          'Active Geometry Kernel does not expose native STL import',
        );
      final mesh = await (kernel as MeshGeometryKernelAPI).importStl(
        request.source.path,
        projectId: request.projectId,
        format: stlKernelFormat(request.stlEncoding),
        onProgress: (_) {},
      );
      document = ImportedCadDocument(
        id: mesh.persistentId,
        projectId: request.projectId,
        sourcePath: request.source.path,
        format: request.format,
        registeredPath: request.source.path,
        mesh: mesh,
        validation: const [],
      );
    } else if (request.format == CadImportFormat.step ||
        request.format == CadImportFormat.iges) {
      if (kernel is! InterchangeGeometryKernelAPI)
        throw StateError(
          'Active Geometry Kernel does not expose CAD interchange',
        );
      final interchange = kernel as InterchangeGeometryKernelAPI;
      final shape = await interchange.importFile(
        request.source.path,
        request.format == CadImportFormat.step
            ? KernelExchangeFormat.step
            : KernelExchangeFormat.iges,
        projectId: request.projectId,
        onProgress: (_) {},
      );
      final diagnostics = await interchange.diagnose(shape);
      document = ImportedCadDocument(
        id: shape.persistentId,
        projectId: request.projectId,
        sourcePath: request.source.path,
        format: request.format,
        registeredPath: request.source.path,
        shape: shape,
        validation: diagnostics
            .map((e) => '${e.severity}:${e.code}:${e.message}')
            .toList(),
      );
    } else {
      throw UnsupportedError(
        '${request.format.name.toUpperCase()} import is not exposed by the official Geometry Kernel',
      );
    }
    progress = .8;
    validation.validateDocument(document);
    final registered = await repository.registerImportSource(request);
    final persistedDocument = ImportedCadDocument(
      id: document.id,
      projectId: document.projectId,
      sourcePath: document.sourcePath,
      format: document.format,
      registeredPath: registered.path,
      mesh: document.mesh,
      shape: document.shape,
      validation: document.validation,
    );
    await repository.recordImport(persistedDocument);
    progress = 1;
    return persistedDocument;
  }
}
