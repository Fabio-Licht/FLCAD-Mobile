import '../api/import_export_api.dart';
import '../engine/import_engine.dart';

class IgesImporter {
  const IgesImporter(this.engine);
  final ImportEngine engine;
  Future<ImportedCadDocument> import(CadImportRequest request) =>
      engine.execute(request);
  static const entities = ['surfaces', 'solids', 'curves'];
}
