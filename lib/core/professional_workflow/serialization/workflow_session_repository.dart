import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../storage/local_storage_service.dart';
import '../session/engineering_session.dart';

class WorkflowSessionRepository {
  WorkflowSessionRepository({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();
  final LocalStorageService _storage;
  final Map<String, Future<void>> _writes = {};

  Future<File> save(EngineeringWorkflowSession session) async {
    final previous = _writes[session.id] ?? Future<void>.value();
    late final File result;
    final write = previous.catchError((_) {}).then((_) async {
      result = await _write(session);
    });
    _writes[session.id] = write;
    await write;
    if (identical(_writes[session.id], write)) _writes.remove(session.id);
    return result;
  }

  Future<File> _write(EngineeringWorkflowSession session) async {
    final jobs = await _storage.getJobsDirectory();
    final directory = Directory(
      path.join(jobs.path, session.projectId, 'Sessions'),
    );
    await directory.create(recursive: true);
    final file = File(path.join(directory.path, '${_safe(session.id)}.json'));
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent(' ').convert({
        'schema': 'flcad.engineering-session',
        'version': 1,
        'id': session.id,
        'projectId': session.projectId,
        'startedAt': session.startedAt.toUtc().toIso8601String(),
        'events': session.events
            .map(
              (event) => {
                'timestamp': event.timestamp.toUtc().toIso8601String(),
                'type': event.type.name,
                'name': event.name,
                'durationMs': event.duration.inMilliseconds,
                'accepted': event.accepted,
                'metadata': event.metadata,
              },
            )
            .toList(),
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    return temporary.rename(file.path);
  }

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
