import '../api/import_export_api.dart';
import '../engine/import_engine.dart';

class StlImporter {
  const StlImporter(this.engine);
  final ImportEngine engine;
  Future<ImportedCadDocument> import(CadImportRequest request) =>
      engine.execute(request);
}
