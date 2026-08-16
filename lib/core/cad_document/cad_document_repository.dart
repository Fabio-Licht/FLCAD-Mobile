import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'cad_document.dart';

class CadDocumentRepository {
  const CadDocumentRepository();
  File file(Directory project) =>
      File(path.join(project.path, 'cad-document.json'));
  Future<CadDocument> load(String projectId, Directory project) async {
    final source = file(project);
    if (!await source.exists()) return CadDocument.empty(projectId);
    final value = CadDocument.fromJson(
      Map<String, dynamic>.from(jsonDecode(await source.readAsString()) as Map),
    );
    if (value.projectId != projectId) {
      throw StateError('CAD document project identity mismatch.');
    }
    return value;
  }

  Future<void> save(CadDocument document, Directory project) async {
    await _atomic(file(project), document.toJson());
  }

  File historyFile(Directory project) =>
      File(path.join(project.path, 'cad-document-history.json'));

  Future<CadDocumentHistoryState> loadHistory(Directory project) async {
    final source = historyFile(project);
    if (!await source.exists()) return const CadDocumentHistoryState();
    final json = Map<String, dynamic>.from(
      jsonDecode(await source.readAsString()) as Map,
    );
    return CadDocumentHistoryState(
      undo: (json['undo'] as List? ?? const [])
          .map(
            (value) =>
                CadDocument.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(),
      redo: (json['redo'] as List? ?? const [])
          .map(
            (value) =>
                CadDocument.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(),
    );
  }

  Future<void> saveHistory(
    Directory project, {
    required Iterable<CadDocument> undo,
    required Iterable<CadDocument> redo,
  }) => _atomic(historyFile(project), {
    'schema': 'flcad.cad-document-history',
    'version': 1,
    'undo': undo.map((value) => value.toJson()).toList(),
    'redo': redo.map((value) => value.toJson()).toList(),
  });

  Future<void> _atomic(File target, Map<String, dynamic> value) async {
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsString(jsonEncode(value), flush: true);
    if (await target.exists()) await target.delete();
    await temporary.rename(target.path);
  }
}

class CadDocumentHistoryState {
  const CadDocumentHistoryState({this.undo = const [], this.redo = const []});
  final List<CadDocument> undo;
  final List<CadDocument> redo;
}
