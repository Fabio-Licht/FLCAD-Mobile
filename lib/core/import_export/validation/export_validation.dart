// ignore_for_file: curly_braces_in_flow_control_structures
import '../../cad_kernel/io/kernel_io_models.dart';
import '../api/import_export_api.dart';

class ExportValidation {
  const ExportValidation();
  void validateRequest(CadExportRequest request) {
    if (request.shape.metadata['temporary'] == true)
      throw StateError('Temporary entities cannot be exported');
    final extension = request.destination.path.split('.').last.toLowerCase();
    final allowed = switch (request.format) {
      CadExportFormat.step => {'step', 'stp'},
      CadExportFormat.iges => {'iges', 'igs'},
      CadExportFormat.stl => {'stl'},
      CadExportFormat.obj => {'obj'},
    };
    if (!allowed.contains(extension))
      throw FormatException(
        'Destination extension .$extension does not match ${request.format.name.toUpperCase()}',
      );
  }

  void validateDiagnostics(List<GeometryDiagnostic> diagnostics) {
    final invalid = diagnostics.where((e) {
      final value = '${e.code} ${e.message}'.toLowerCase();
      return e.severity.toLowerCase() == 'error' ||
          value.contains('open shell') ||
          value.contains('open surface') ||
          value.contains('orientation') ||
          value.contains('degenerate') ||
          value.contains('invalid');
    }).toList();
    if (invalid.isNotEmpty)
      throw StateError(
        'Export blocked by Geometry Kernel validation: ${invalid.map((e) => e.message).join('; ')}',
      );
  }
}
