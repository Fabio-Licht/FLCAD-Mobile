import '../api/import_export_api.dart';

class ImportExportWorkspace {
  const ImportExportWorkspace(this.api);
  final ImportExportApi api;
  Map<String, dynamic> get explorer => {
    'documents': api.documents.map((e) => e.toJson()).toList(),
  };
  Map<String, dynamic> viewport(ImportedCadDocument document) => {
    'documentId': document.id,
    'fitView': true,
    'selectionCleared': true,
    'boundingBox': document.mesh?.bounds.toJson(),
    'validation': document.validation,
  };
}
