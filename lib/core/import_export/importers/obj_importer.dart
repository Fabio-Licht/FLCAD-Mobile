import '../api/import_export_api.dart';

class ObjImporter {
  const ObjImporter();
  Future<ImportedCadDocument> import(CadImportRequest request) =>
      throw UnsupportedError(
        'OBJ import requires an official Geometry Kernel capability',
      );
}
