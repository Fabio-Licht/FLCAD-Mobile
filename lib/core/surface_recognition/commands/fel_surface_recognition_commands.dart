import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../mesh_foundation/models/mesh_models.dart';
import '../api/surface_recognition_api.dart';

class SurfaceRecognitionFelCommand implements FELCommand {
  const SurfaceRecognitionFelCommand(this.name, this.api, this.activeMesh);
  @override
  final String name;
  final SurfaceRecognitionApi api;
  final MeshEntity? Function() activeMesh;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    if (name == 'RUN RECOGNITION') {
      final mesh =
          activeMesh() ?? (throw StateError('No active mesh for recognition'));
      value = (await api.run(mesh)).toJson();
    } else {
      final mesh = activeMesh(),
          report = mesh == null ? null : api.forMesh(mesh.id);
      if (report == null) {
        throw StateError('Surface recognition has not been executed');
      }
      value = switch (name) {
        'SHOW RECOGNITION' || 'SHOW RECOGNITION REPORT' => report.toJson(),
        'SHOW REGIONS' =>
          report.classifications.map((e) => e.toJson()).toList(),
        'SHOW PLANES' =>
          report.classifications
              .where((e) => e.type.name == 'plane')
              .map((e) => e.toJson())
              .toList(),
        'SHOW CYLINDERS' =>
          report.classifications
              .where((e) => e.type.name == 'cylinder')
              .map((e) => e.toJson())
              .toList(),
        'SHOW CONES' =>
          report.classifications
              .where((e) => e.type.name == 'cone')
              .map((e) => e.toJson())
              .toList(),
        'SHOW SPHERES' =>
          report.classifications
              .where((e) => e.type.name == 'sphere')
              .map((e) => e.toJson())
              .toList(),
        'SHOW TORI' =>
          report.classifications
              .where((e) => e.type.name == 'torus')
              .map((e) => e.toJson())
              .toList(),
        'SHOW FREEFORM' =>
          report.classifications
              .where((e) => e.type.name == 'freeform')
              .map((e) => e.toJson())
              .toList(),
        'SHOW UNKNOWN' =>
          report.classifications
              .where((e) => e.type.name == 'unknown')
              .map((e) => e.toJson())
              .toList(),
        'SHOW REGION GRAPH' => report.graph.toJson(),
        'SHOW RECOGNITION ANALYTICS' => report.analytics.toJson(),
        'SHOW RECOGNITION ADVISOR' =>
          report.advice.map((e) => e.toJson()).toList(),
        'SHOW CONFIDENCE' || 'SHOW CONFIDENCE MAP' => {
          for (final e in report.classifications) e.region.id: e.confidence,
        },
        _ => {'command': name, 'reportId': report.id, 'status': 'available'},
      };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createSurfaceRecognitionFelCommands(
  SurfaceRecognitionApi api,
  MeshEntity? Function() activeMesh,
) {
  const required = [
    'RUN RECOGNITION',
    'SHOW RECOGNITION',
    'SHOW REGIONS',
    'SHOW PLANES',
    'SHOW CYLINDERS',
    'SHOW CONES',
    'SHOW SPHERES',
    'SHOW TORI',
    'SHOW FREEFORM',
    'SHOW UNKNOWN',
    'SHOW CONFIDENCE',
    'SHOW RECOGNITION TREE',
    'SHOW REGION GRAPH',
    'SHOW RECOGNITION REPORT',
    'SHOW RECOGNITION ANALYTICS',
    'SHOW CONFIDENCE MAP',
    'SHOW RECOGNITION ADVISOR',
  ];
  const subjects = [
    'REGION',
    'PLANE',
    'CYLINDER',
    'CONE',
    'SPHERE',
    'TORUS',
    'FREEFORM',
    'UNKNOWN',
  ];
  const operations = [
    'LIST',
    'SELECT',
    'HIGHLIGHT',
    'INSPECT',
    'VALIDATE',
    'COMPARE',
    'EXPORT',
    'PERSIST',
    'SHOW AREA',
    'SHOW NORMAL',
    'SHOW BOUNDS',
    'SHOW HEALTH',
    'SHOW EVIDENCE',
    'SHOW PARAMETERS',
    'SHOW HISTORY',
  ];
  final names = <String>{
    ...required,
    for (final subject in subjects)
      for (final operation in operations) '$operation $subject',
  };
  return [
    for (final name in names)
      SurfaceRecognitionFelCommand(name, api, activeMesh),
  ];
}
