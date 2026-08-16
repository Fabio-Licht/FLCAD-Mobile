import '../api/import_export_api.dart';

class ObjExporter {
  const ObjExporter();
  Future<CadExportResult> export(CadExportRequest request) =>
      throw UnsupportedError(
        'OBJ export requires an official Geometry Kernel capability',
      );
}
