// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../api/import_export_api.dart';

class ImportExportRepository {
  const ImportExportRepository();
  static const folders = [
    'CAD/Imports',
    'CAD/Exports',
    'CAD/RecentFiles',
    'CAD/ImportHistory',
    'CAD/ExportHistory',
  ];
  Future<void> ensureStructure(Directory project) async {
    for (final folder in folders) {
      await Directory(path.join(project.path, folder)).create(recursive: true);
    }
  }

  Future<File> registerImportSource(CadImportRequest request) async {
    await ensureStructure(request.projectDirectory);
    final destination = File(
      path.join(
        request.projectDirectory.path,
        'CAD',
        'Imports',
        path.basename(request.source.path),
      ),
    );
    if (path.equals(request.source.path, destination.path))
      return request.source;
    if (await destination.exists())
      throw StateError(
        'An imported file with this name already exists: ${destination.path}',
      );
    return request.source.copy(destination.path);
  }

  Future<File> registerExport(CadExportRequest request) async {
    await ensureStructure(request.projectDirectory);
    final destination = File(
      path.join(
        request.projectDirectory.path,
        'CAD',
        'Exports',
        path.basename(request.destination.path),
      ),
    );
    if (path.equals(request.destination.path, destination.path))
      return request.destination;
    if (await destination.exists()) await destination.delete();
    return request.destination.copy(destination.path);
  }

  Future<void> recordImport(ImportedCadDocument document) async {
    final root = Directory(document.registeredPath).parent.parent.parent;
    await _append(
      File(path.join(root.path, 'CAD', 'ImportHistory', 'history.jsonl')),
      document.toJson(),
    );
    await _recent(root, document.registeredPath, 'import');
  }

  Future<void> recordExport(Directory root, CadExportResult result) async {
    await _append(
      File(path.join(root.path, 'CAD', 'ExportHistory', 'history.jsonl')),
      result.toJson(),
    );
    await _recent(root, result.registeredPath, 'export');
  }

  Future<void> _recent(Directory root, String file, String operation) =>
      _append(
        File(path.join(root.path, 'CAD', 'RecentFiles', 'recent.jsonl')),
        {'path': file, 'operation': operation},
      );
  Future<void> _append(File file, Map<String, dynamic> value) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(value)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}
