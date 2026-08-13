import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_recognition/models/recognition_models.dart';
import '../api/professional_recognition_api.dart';

class ProfessionalRecognitionFELCommand implements FELCommand {
  ProfessionalRecognitionFELCommand(this.name, this.action, this.api);
  @override
  final String name;
  final String action;
  final ProfessionalRecognitionApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object value;
    if (action == 'recognize') {
      final mesh = context.activeMesh;
      if (mesh == null) throw StateError('A mesh must be selected first');
      value = await api.recognize([
        RecognitionContext(
          observation: RecognitionObservation(
            projectId: context.projectId,
            meshId: mesh.id,
            regionId: context.activeRegion?.id ?? 'mesh:${mesh.id}',
            points: mesh.vertices.map((v) => Vector3(v.x, v.y, v.z)).toList(),
            normals: List.generate(mesh.triangles.length, (i) {
              final n = mesh.triangleNormal(i);
              return Vector3(n.x, n.y, n.z);
            }),
            meshFingerprint:
                '${mesh.id}:${mesh.vertices.length}:${mesh.triangles.length}',
            regionFingerprint:
                '${context.activeRegion?.id ?? mesh.id}:${mesh.triangles.length}',
          ),
        ),
      ]);
    } else {
      final report = api.last;
      value = switch (action) {
        'features' => report.features,
        'primitives' => report.primitives,
        'patterns' => report.patterns,
        'topology' => report.relations,
        'featureGraph' => report.features,
        'primitiveGraph' => api.engine.urf.graph.values,
        'manufacturing' => report.manufacturing,
        'function' => report.functions,
        'report' => report,
        'export' => api.exportReport(),
        _ => throw UnsupportedError(action),
      };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createProfessionalRecognitionFELCommands({
  ProfessionalRecognitionApi? api,
}) {
  final value = api ?? ProfessionalRecognitionApi();
  return [
    ProfessionalRecognitionFELCommand('RECOGNIZE FEATURES', 'recognize', value),
    ProfessionalRecognitionFELCommand(
      'RECOGNIZE PRIMITIVES',
      'recognize',
      value,
    ),
    ProfessionalRecognitionFELCommand('RECOGNIZE PATTERNS', 'patterns', value),
    ProfessionalRecognitionFELCommand('RECOGNIZE TOPOLOGY', 'topology', value),
    ProfessionalRecognitionFELCommand(
      'SHOW FEATURE GRAPH',
      'featureGraph',
      value,
    ),
    ProfessionalRecognitionFELCommand(
      'SHOW PRIMITIVE GRAPH',
      'primitiveGraph',
      value,
    ),
    ProfessionalRecognitionFELCommand(
      'SHOW MANUFACTURING',
      'manufacturing',
      value,
    ),
    ProfessionalRecognitionFELCommand('SHOW FUNCTION', 'function', value),
    ProfessionalRecognitionFELCommand(
      'SHOW RECOGNITION REPORT',
      'report',
      value,
    ),
    ProfessionalRecognitionFELCommand('EXPORT RECOGNITION', 'export', value),
  ];
}
