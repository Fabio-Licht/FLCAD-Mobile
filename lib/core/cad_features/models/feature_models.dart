import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';

enum CadFeatureKind {
  extrude,
  revolve,
  sweep,
  loft,
  booleanUnion,
  booleanSubtract,
  booleanIntersect,
  offset,
  shell,
  draft,
  mirror,
  linearPattern,
  circularPattern,
}

enum CadFeatureStatus { valid, failed, unavailable }

class CadFeature {
  const CadFeature({
    required this.id,
    required this.projectId,
    required this.kind,
    required this.inputs,
    required this.output,
    required this.parameters,
    required this.dependencies,
    required this.createdAt,
    required this.user,
    required this.revision,
    required this.status,
    required this.buildTime,
    this.diagnostics = const [],
    this.humanDecisions = const {},
  });
  final String id, projectId, user;
  final CadFeatureKind kind;
  final List<ShapeHandle> inputs;
  final ShapeHandle? output;
  final Map<String, dynamic> parameters, humanDecisions;
  final List<String> dependencies;
  final DateTime createdAt;
  final int revision;
  final CadFeatureStatus status;
  final Duration buildTime;
  final List<GeometryDiagnostic> diagnostics;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'kind': kind.name,
    'inputs': inputs.map((e) => e.toJson()).toList(),
    'output': output?.toJson(),
    'parameters': parameters,
    'dependencies': dependencies,
    'createdAt': createdAt.toIso8601String(),
    'user': user,
    'revision': revision,
    'status': status.name,
    'buildTimeMicros': buildTime.inMicroseconds,
    'diagnostics': diagnostics
        .map(
          (e) => {
            'code': e.code,
            'message': e.message,
            'severity': e.severity,
            'shapeId': e.shapeId,
            'metadata': e.metadata,
          },
        )
        .toList(),
    'humanDecisions': humanDecisions,
  };
  factory CadFeature.fromJson(Map<String, dynamic> json) => CadFeature(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    kind: CadFeatureKind.values.byName(json['kind'] as String),
    inputs: (json['inputs'] as List)
        .map((e) => ShapeHandle.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    output: json['output'] == null
        ? null
        : ShapeHandle.fromJson(
            Map<String, dynamic>.from(json['output'] as Map),
          ),
    parameters: Map<String, dynamic>.from(json['parameters'] as Map),
    dependencies: (json['dependencies'] as List).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    user: json['user'] as String,
    revision: json['revision'] as int,
    status: CadFeatureStatus.values.byName(json['status'] as String),
    buildTime: Duration(microseconds: json['buildTimeMicros'] as int),
    diagnostics: (json['diagnostics'] as List).map((e) {
      final d = Map<String, dynamic>.from(e as Map);
      return GeometryDiagnostic(
        code: d['code'] as String,
        message: d['message'] as String,
        severity: d['severity'] as String,
        shapeId: d['shapeId'] as String?,
        metadata: Map<String, dynamic>.from(d['metadata'] as Map? ?? const {}),
      );
    }).toList(),
    humanDecisions: Map<String, dynamic>.from(
      json['humanDecisions'] as Map? ?? const {},
    ),
  );
}

class FeatureResult {
  const FeatureResult(this.feature);
  final CadFeature feature;
  bool get success => feature.status == CadFeatureStatus.valid;
  bool get unavailable => feature.status == CadFeatureStatus.unavailable;
}

class HealingAudit {
  const HealingAudit({
    required this.shape,
    required this.problems,
    required this.proposed,
    required this.executed,
    this.result,
  });
  final ShapeHandle shape;
  final List<GeometryDiagnostic> problems;
  final List<HealingProposal> proposed;
  final List<String> executed;
  final ShapeHandle? result;
}
