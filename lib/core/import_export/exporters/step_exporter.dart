import '../api/import_export_api.dart';
import '../engine/export_engine.dart';

class StepExporter {
  const StepExporter(this.engine);
  final ExportEngine engine;
  Future<CadExportResult> export(CadExportRequest request) =>
      engine.execute(request);
}
