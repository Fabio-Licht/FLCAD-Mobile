import '../models/reconstruction_models.dart';

class WorkflowTimeline {
  final List<WorkflowTimelineEntry> _entries = [];
  List<WorkflowTimelineEntry> get entries => List.unmodifiable(_entries);
  void record(
    String stageId,
    ReconstructionStageStatus status,
    String reason,
  ) => _entries.add(
    WorkflowTimelineEntry(
      _entries.length + 1,
      stageId,
      status,
      DateTime.now().toUtc(),
      reason,
    ),
  );
  List<WorkflowTimelineEntry> forStage(String id) =>
      _entries.where((e) => e.stageId == id).toList();
}
