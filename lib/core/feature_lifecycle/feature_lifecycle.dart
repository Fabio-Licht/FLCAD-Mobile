import '../cad_document/cad_document.dart';

enum FeatureLifecycleState { created, editing, closed, saved }

class FeatureLifecycleEvent {
  const FeatureLifecycleEvent({
    required this.sequence,
    required this.action,
    required this.timestamp,
    required this.command,
  });

  final int sequence;
  final String action;
  final DateTime timestamp;
  final String command;

  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'action': action,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'command': command,
  };

  factory FeatureLifecycleEvent.fromJson(Map<String, dynamic> json) =>
      FeatureLifecycleEvent(
        sequence: json['sequence'] as int,
        action: json['action'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        command: json['command'] as String? ?? json['action'] as String,
      );
}

/// Durable, entity-neutral lifecycle definition embedded in a project entity.
class FeatureLifecycleRecord {
  const FeatureLifecycleRecord({
    required this.featureId,
    required this.workspace,
    required this.state,
    required this.createdBy,
    required this.parameters,
    required this.references,
    required this.childIds,
    required this.dependencyIds,
    required this.dependentIds,
    required this.treeParentId,
    required this.treeOrder,
    required this.history,
    required this.revision,
    this.solverContract = 'flcad.geometry-constraint-solver/v1',
    this.activationGesture = 'doubleClick',
  });

  final String featureId;
  final String workspace;
  final FeatureLifecycleState state;
  final String createdBy;
  final Map<String, dynamic> parameters;
  final List<String> references;
  final List<String> childIds;
  final List<String> dependencyIds;
  final List<String> dependentIds;
  final String? treeParentId;
  final int treeOrder;
  final List<FeatureLifecycleEvent> history;
  final int revision;
  final String solverContract;
  final String activationGesture;

  Map<String, dynamic> toJson() => {
    'schema': 'flcad.feature-lifecycle',
    'version': 1,
    'featureId': featureId,
    'workspace': workspace,
    'state': state.name,
    'createdBy': createdBy,
    'parameters': parameters,
    'references': references,
    'childIds': childIds,
    'dependencyIds': dependencyIds,
    'dependentIds': dependentIds,
    'treeParentId': treeParentId,
    'treeOrder': treeOrder,
    'history': history.map((event) => event.toJson()).toList(),
    'revision': revision,
    'solverContract': solverContract,
    'activationGesture': activationGesture,
  };

  factory FeatureLifecycleRecord.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 'flcad.feature-lifecycle') {
      throw const FormatException('Unsupported Feature Lifecycle schema.');
    }
    return FeatureLifecycleRecord(
      featureId: json['featureId'] as String,
      workspace: json['workspace'] as String,
      state: FeatureLifecycleState.values.byName(json['state'] as String),
      createdBy: json['createdBy'] as String,
      parameters: Map<String, dynamic>.from(
        json['parameters'] as Map? ?? const {},
      ),
      references: (json['references'] as List? ?? const []).cast<String>(),
      childIds: (json['childIds'] as List? ?? const []).cast<String>(),
      dependencyIds: (json['dependencyIds'] as List? ?? const [])
          .cast<String>(),
      dependentIds: (json['dependentIds'] as List? ?? const []).cast<String>(),
      treeParentId: json['treeParentId'] as String?,
      treeOrder: json['treeOrder'] as int? ?? 0,
      history: (json['history'] as List? ?? const [])
          .map(
            (value) => FeatureLifecycleEvent.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
      revision: json['revision'] as int? ?? 0,
      solverContract:
          json['solverContract'] as String? ??
          'flcad.geometry-constraint-solver/v1',
      activationGesture: json['activationGesture'] as String? ?? 'doubleClick',
    );
  }
}

abstract final class FeatureLifecycleContract {
  static const activationGesture = 'doubleClick';
  static const dataKey = 'featureLifecycle';

  static bool appliesTo(CadDocumentEntity entity) {
    if (entity.data['authoringRoot'] == true) return true;
    return switch (entity.kind) {
      CadDocumentEntityKind.sketch => entity.data['sketch'] is Map,
      CadDocumentEntityKind.surface ||
      CadDocumentEntityKind.shell ||
      CadDocumentEntityKind.solid => true,
      _ => false,
    };
  }

  static FeatureLifecycleRecord require(CadDocumentEntity entity) {
    final raw = entity.data[dataKey];
    if (raw is! Map) {
      throw StateError('${entity.id} does not implement Feature Lifecycle.');
    }
    final record = FeatureLifecycleRecord.fromJson(
      Map<String, dynamic>.from(raw),
    );
    if (record.featureId != entity.id) {
      throw StateError('Feature identity mismatch for ${entity.id}.');
    }
    if (record.solverContract != 'flcad.geometry-constraint-solver/v1' ||
        record.activationGesture != activationGesture) {
      throw StateError('${entity.id} violates the Feature Lifecycle Contract.');
    }
    return record;
  }
}
