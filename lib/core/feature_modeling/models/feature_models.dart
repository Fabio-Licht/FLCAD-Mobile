import '../../utils/id_generator.dart';

enum FeatureType {
  extrude,
  revolve,
  sweep,
  loft,
  boolean,
  shell,
  draft,
  fillet,
  chamfer,
  mirror,
  pattern,
  reference,
}

enum FeatureExecutionState {
  pending,
  queued,
  rebuilding,
  ready,
  suppressed,
  frozen,
  failed,
  edited,
  unsupported,
  kernelUnavailable,
}

enum FeatureRebuildStatus {
  clean,
  dirty,
  queued,
  rebuilding,
  complete,
  failed,
  rolledBack,
}

class FeatureReference {
  const FeatureReference(this.id, {this.kind = 'feature'});
  final String id, kind;
  Map<String, dynamic> toJson() => {'id': id, 'kind': kind};
}

class FeatureInput {
  const FeatureInput(this.name, this.reference);
  final String name;
  final FeatureReference reference;
}

class FeatureOutput {
  const FeatureOutput(this.name, {this.handle});
  final String name;
  final Object? handle;
}

class FeatureResult {
  const FeatureResult({
    required this.success,
    required this.state,
    required this.diagnostics,
    this.outputs = const [],
  });
  final bool success;
  final FeatureExecutionState state;
  final List<String> diagnostics;
  final List<FeatureOutput> outputs;
}

class FeatureDefinition {
  const FeatureDefinition({
    required this.type,
    required this.name,
    this.requiredInputs = const [],
    this.supported = false,
  });
  final FeatureType type;
  final String name;
  final List<String> requiredInputs;
  final bool supported;
}

class FeatureMetadata {
  FeatureMetadata({Map<String, dynamic>? values})
    : values = values ?? <String, dynamic>{};
  final Map<String, dynamic> values;
}

class FeatureContext {
  const FeatureContext({required this.projectId, required this.featureId});
  final String projectId, featureId;
}

class FeatureExecution {
  FeatureExecution({
    required this.featureId,
    required this.state,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();
  final String featureId;
  FeatureExecutionState state;
  final DateTime timestamp;
  final List<String> diagnostics = [];
}

class FeatureInstance {
  FeatureInstance({
    required this.definition,
    List<FeatureInput>? inputs,
    Map<String, dynamic>? parameters,
    List<String>? dependencies,
    this.owner = 'local',
    String? id,
    DateTime? timestamp,
    this.version = 1,
    FeatureMetadata? metadata,
    List<String>? diagnostics,
  }) : id = id ?? 'feature:${IdGenerator.generate()}',
       inputs = inputs ?? <FeatureInput>[],
       parameters = parameters ?? <String, dynamic>{},
       dependencies = dependencies ?? <String>[],
       timestamp = timestamp ?? DateTime.now().toUtc(),
       metadata = metadata ?? FeatureMetadata(),
       diagnostics = diagnostics ?? <String>[];
  final String id, owner;
  final FeatureDefinition definition;
  final List<FeatureInput> inputs;
  final Map<String, dynamic> parameters;
  final List<String> dependencies;
  final DateTime timestamp;
  int version;
  final FeatureMetadata metadata;
  final List<String> diagnostics;
  FeatureExecutionState state = FeatureExecutionState.pending;
  bool suppressed = false, frozen = false;
  FeatureResult? result;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': definition.type.name,
    'name': definition.name,
    'inputs': inputs
        .map((i) => {'name': i.name, 'reference': i.reference.toJson()})
        .toList(),
    'parameters': parameters,
    'dependencies': dependencies,
    'owner': owner,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'metadata': metadata.values,
    'diagnostics': diagnostics,
    'state': state.name,
    'suppressed': suppressed,
    'frozen': frozen,
  };
}

typedef Feature = FeatureInstance;
