import 'dart:convert';
import 'dart:io';
import '../models/surface_operation_models.dart';

class SurfaceOperationRepository {
  SurfaceOperationRepository(this.projectDirectory);
  final Directory projectDirectory;
  final Map<String, SurfaceOperation> operations = {};
  final List<Map<String, dynamic>> history = [];
  static const paths = [
    'CAD/SurfaceOperations',
    'CAD/OperationHistory',
    'CAD/Constraints',
    'CAD/Validation',
    'CAD/OperationAnalytics',
    'CAD/OperationReports',
  ];
  void add(SurfaceOperation value) {
    if (operations.containsKey(value.id)) {
      throw StateError('Duplicate surface operation: ${value.id}');
    }
    operations[value.id] = value;
    record(value, 'created');
  }

  void update(SurfaceOperation value, String event) {
    if (!operations.containsKey(value.id)) {
      throw StateError('Unknown surface operation: ${value.id}');
    }
    operations[value.id] = value;
    record(value, event);
  }

  void record(SurfaceOperation value, String event) => history.add({
    'operationId': value.id,
    'event': event,
    'status': value.status.name,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  });
  String _path(String path) =>
      '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}';
  Future<void> persist(Map<String, dynamic> aggregateAnalytics) async {
    for (final path in paths) {
      await Directory(_path(path)).create(recursive: true);
    }
    for (final operation in operations.values) {
      final safe = operation.id.replaceAll(':', '_');
      Future<void> write(String folder, Object value) => File(
        '${_path(folder)}${Platform.pathSeparator}$safe.json',
      ).writeAsString(jsonEncode(value));
      await write('CAD/SurfaceOperations', operation.toJson());
      await write(
        'CAD/Constraints',
        operation.constraints.map((e) => e.toJson()).toList(),
      );
      await write('CAD/Validation', operation.validation?.toJson() ?? const {});
      await write('CAD/OperationReports', {
        'operation': operation.toJson(),
        'history': history
            .where((e) => e['operationId'] == operation.id)
            .toList(),
      });
    }
    await File(
      '${_path('CAD/OperationHistory')}${Platform.pathSeparator}history.json',
    ).writeAsString(jsonEncode(history));
    await File(
      '${_path('CAD/OperationAnalytics')}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(aggregateAnalytics));
  }
}
