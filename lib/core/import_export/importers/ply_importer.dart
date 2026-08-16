import '../api/import_export_api.dart';

class PlyImporter {
  const PlyImporter();
  Future<ImportedCadDocument> import(CadImportRequest request) =>
      throw UnsupportedError(
        'PLY import requires an official Geometry Kernel capability',
      );
}
