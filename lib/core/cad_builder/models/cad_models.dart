import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';

class CadEntity {
  const CadEntity({
    required this.handle,
    required this.projectId,
    required this.origin,
    required this.dependencies,
    required this.valid,
    required this.diagnostics,
    required this.createdAt,
    this.statistics = const {},
  });
  final ShapeHandle handle;
  final String projectId, origin;
  final List<String> dependencies;
  final bool valid;
  final List<GeometryDiagnostic> diagnostics;
  final DateTime createdAt;
  final Map<String, dynamic> statistics;
  Map<String, dynamic> toJson() => {
    'handle': handle.toJson(),
    'projectId': projectId,
    'origin': origin,
    'dependencies': dependencies,
    'valid': valid,
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
    'createdAt': createdAt.toIso8601String(),
    'statistics': statistics,
  };
  factory CadEntity.fromJson(Map<String, dynamic> json) => CadEntity(
    handle: ShapeHandle.fromJson(
      Map<String, dynamic>.from(json['handle'] as Map),
    ),
    projectId: json['projectId'] as String,
    origin: json['origin'] as String,
    dependencies: (json['dependencies'] as List).cast<String>(),
    valid: json['valid'] as bool,
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
    createdAt: DateTime.parse(json['createdAt'] as String),
    statistics: Map<String, dynamic>.from(
      json['statistics'] as Map? ?? const {},
    ),
  );
}

class CadBuildResult {
  const CadBuildResult({this.entity, required this.diagnostics});
  final CadEntity? entity;
  final List<GeometryDiagnostic> diagnostics;
  bool get success => entity != null && entity!.valid;
}
