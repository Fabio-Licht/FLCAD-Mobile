import 'dart:io';

import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../engine/export_engine.dart';
import '../engine/import_engine.dart';
import '../repository/import_export_repository.dart';
import '../runtime/import_export_runtime.dart';

enum CadImportFormat { stl, step, iges, obj, ply }

enum CadExportFormat { step, iges, stl, obj }

enum StlEncoding { autoDetect, binary, ascii }

class ImportedCadDocument {
  const ImportedCadDocument({
    required this.id,
    required this.projectId,
    required this.sourcePath,
    required this.format,
    required this.registeredPath,
    required this.validation,
    this.shape,
    this.mesh,
  });
  final String id, projectId, sourcePath, registeredPath;
  final CadImportFormat format;
  final ShapeHandle? shape;
  final KernelMeshHandle? mesh;
  final List<String> validation;
  bool get isMesh => mesh != null;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'sourcePath': sourcePath,
    'registeredPath': registeredPath,
    'format': format.name,
    'shape': shape?.toJson(),
    'mesh': mesh == null
        ? null
        : {
            'persistentId': mesh!.persistentId,
            'kernelId': mesh!.kernelId,
            'fingerprint': mesh!.fingerprint,
            'vertexCount': mesh!.vertexCount,
            'triangleCount': mesh!.triangleCount,
            'bounds': mesh!.bounds.toJson(),
            'hasNormals': mesh!.hasNormals,
            'degenerateTriangleCount': mesh!.degenerateTriangleCount,
            'metadata': mesh!.metadata,
          },
    'validation': validation,
  };
}

class CadImportRequest {
  const CadImportRequest({
    required this.projectId,
    required this.projectDirectory,
    required this.source,
    required this.format,
    this.stlEncoding = StlEncoding.autoDetect,
  });
  final String projectId;
  final Directory projectDirectory;
  final File source;
  final CadImportFormat format;
  final StlEncoding stlEncoding;
}

class CadExportRequest {
  const CadExportRequest({
    required this.projectId,
    required this.projectDirectory,
    required this.destination,
    required this.format,
    required this.shape,
  });
  final String projectId;
  final Directory projectDirectory;
  final File destination;
  final CadExportFormat format;
  final ShapeHandle shape;
}

class CadExportResult {
  const CadExportResult({
    required this.destination,
    required this.registeredPath,
    required this.format,
    required this.validation,
  });
  final String destination, registeredPath;
  final CadExportFormat format;
  final List<String> validation;
  Map<String, dynamic> toJson() => {
    'destination': destination,
    'registeredPath': registeredPath,
    'format': format.name,
    'validation': validation,
  };
}

class ImportExportApi {
  ImportExportApi({
    required GeometryKernelAPI kernel,
    required ImportExportRepository repository,
    ImportExportRuntime? runtime,
  }) : runtime = runtime ?? ImportExportRuntime(),
       _import = ImportEngine(kernel: kernel, repository: repository),
       _export = ExportEngine(kernel: kernel, repository: repository);
  final ImportExportRuntime runtime;
  final ImportEngine _import;
  final ExportEngine _export;
  final List<ImportedCadDocument> _documents = [];
  List<ImportedCadDocument> get documents => List.unmodifiable(_documents);

  Future<ImportedCadDocument> import(CadImportRequest request) async {
    final document = await runtime.runImport(
      () => _import.execute(request),
      onProgress: _import.progress,
    );
    _documents.add(document);
    return document;
  }

  Future<CadExportResult> export(CadExportRequest request) => runtime.runExport(
    () => _export.execute(request),
    onProgress: _export.progress,
  );
}

KernelImportFormat stlKernelFormat(StlEncoding value) => switch (value) {
  StlEncoding.autoDetect => KernelImportFormat.autoDetect,
  StlEncoding.binary => KernelImportFormat.binaryStl,
  StlEncoding.ascii => KernelImportFormat.asciiStl,
};
