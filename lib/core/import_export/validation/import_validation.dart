// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:io';

import '../api/import_export_api.dart';

class ImportValidation {
  const ImportValidation();
  Future<void> validateFile(CadImportRequest request) async {
    if (!await request.source.exists())
      throw const FileSystemException('Import file does not exist');
    if (await request.source.length() == 0)
      throw const FormatException('Import file is empty');
    final extension = request.source.path.split('.').last.toLowerCase();
    final allowed = switch (request.format) {
      CadImportFormat.stl => {'stl'},
      CadImportFormat.step => {'step', 'stp'},
      CadImportFormat.iges => {'iges', 'igs'},
      CadImportFormat.obj => {'obj'},
      CadImportFormat.ply => {'ply'},
    };
    if (!allowed.contains(extension))
      throw FormatException(
        'File extension .$extension does not match ${request.format.name.toUpperCase()}',
      );
  }

  void validateDocument(ImportedCadDocument document) {
    if (document.shape == null && document.mesh == null)
      throw const FormatException('Geometry Kernel returned empty geometry');
    final mesh = document.mesh;
    if (mesh != null) {
      if (mesh.vertexCount == 0 || mesh.triangleCount == 0)
        throw const FormatException('Imported mesh contains no geometry');
      if (mesh.degenerateTriangleCount > 0)
        throw FormatException(
          'Imported mesh contains ${mesh.degenerateTriangleCount} degenerate entities',
        );
    }
    if (document.validation.any((e) => e.toLowerCase().startsWith('error:')))
      throw FormatException(
        'Geometry Kernel rejected imported geometry: ${document.validation.join('; ')}',
      );
  }
}
