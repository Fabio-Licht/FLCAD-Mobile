import '../models/cad_models.dart';

enum CadHistoryAction { create, delete, undo, replay }

class CadHistoryEntry {
  const CadHistoryEntry(this.action, this.entity, this.timestamp, this.actor);
  final CadHistoryAction action;
  final CadEntity entity;
  final DateTime timestamp;
  final String actor;
}

class CadBuilderHistory {
  final List<CadHistoryEntry> _entries = [];
  List<CadHistoryEntry> get entries => List.unmodifiable(_entries);
  void record(
    CadHistoryAction action,
    CadEntity entity, {
    String actor = 'cad-builder',
  }) => _entries.add(CadHistoryEntry(action, entity, DateTime.now(), actor));
  CadHistoryEntry? undoCandidate() =>
      _entries.where((e) => e.action == CadHistoryAction.create).lastOrNull;
  List<CadEntity> replay() => _entries
      .where(
        (e) =>
            e.action == CadHistoryAction.create ||
            e.action == CadHistoryAction.replay,
      )
      .map((e) => e.entity)
      .toList(growable: false);
}
