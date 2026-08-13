import '../models/surface_generation_models.dart';

enum SurfaceGenerationHistoryAction {
  generate,
  invalid,
  unavailable,
  failed,
  delete,
  validate,
  healingProposal,
}

class SurfaceGenerationHistoryEntry {
  const SurfaceGenerationHistoryEntry(
    this.action,
    this.candidateId,
    this.timestamp,
    this.status,
    this.diagnostics, {
    this.surfaceId,
  });
  final SurfaceGenerationHistoryAction action;
  final String candidateId;
  final DateTime timestamp;
  final SurfaceGenerationStatus status;
  final List<String> diagnostics;
  final String? surfaceId;
}

class SurfaceGenerationHistory {
  final List<SurfaceGenerationHistoryEntry> _entries = [];
  List<SurfaceGenerationHistoryEntry> get entries =>
      List.unmodifiable(_entries);
  void record(
    SurfaceGenerationHistoryAction action,
    String candidateId,
    SurfaceGenerationStatus status,
    List<String> diagnostics, {
    String? surfaceId,
  }) => _entries.add(
    SurfaceGenerationHistoryEntry(
      action,
      candidateId,
      DateTime.now(),
      status,
      diagnostics,
      surfaceId: surfaceId,
    ),
  );
}
