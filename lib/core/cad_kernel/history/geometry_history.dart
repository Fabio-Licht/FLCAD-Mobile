import '../ids/persistent_id_service.dart';
import '../models/kernel_models.dart';

class GeometryHistory {
  GeometryHistory({PersistentIdService ids = const PersistentIdService()})
    : ids = ids;
  final PersistentIdService ids;
  final List<GeometryHistoryRecord> _records = [];
  void record({
    required String projectId,
    required GeometryHistoryAction action,
    required List<ShapeHandle> shapes,
    required String transactionId,
    required String actor,
    Map<String, dynamic> metadata = const {},
  }) => _records.add(
    GeometryHistoryRecord(
      ids.create(projectId, 'history'),
      projectId,
      action,
      shapes.map((e) => e.persistentId).toList(),
      transactionId,
      DateTime.now(),
      actor,
      metadata,
    ),
  );
  List<GeometryHistoryRecord> forProject(String id) =>
      _records.where((e) => e.projectId == id).toList(growable: false);
}
