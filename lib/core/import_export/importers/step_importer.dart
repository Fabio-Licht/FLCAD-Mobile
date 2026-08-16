import '../api/import_export_api.dart';
import '../engine/import_engine.dart';

class StepImporter {
  const StepImporter(this.engine);
  final ImportEngine engine;
  Future<ImportedCadDocument> import(CadImportRequest request) =>
      engine.execute(request);
  static const supportedSchemas = ['AP203', 'AP214'];
  static const preparedSchemas = ['AP242'];
}
