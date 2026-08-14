import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../mesh_foundation/models/mesh_models.dart';
import '../../surface_recognition/models/surface_recognition_models.dart';
import '../api/surface_fitting_api.dart';

class SurfaceFittingFelCommand implements FELCommand {
  const SurfaceFittingFelCommand(
    this.name,
    this.api,
    this.mesh,
    this.recognition,
  );
  @override
  final String name;
  final SurfaceFittingApi api;
  final MeshEntity? Function() mesh;
  final SurfaceRecognitionReport? Function() recognition;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    if (name == 'RUN SURFACE FITTING') {
      final activeMesh = mesh() ?? (throw StateError('No active mesh')),
          activeRecognition =
              recognition() ??
              (throw StateError('No surface recognition report'));
      value = (await api.run(
        mesh: activeMesh,
        recognition: activeRecognition,
        projectId: context.projectId,
      )).toJson();
    } else {
      final active = recognition(),
          report = active == null ? null : api.forRecognition(active.id);
      if (report == null) {
        throw StateError('Surface fitting has not been executed');
      }
      value = switch (name) {
        'SHOW SURFACES' => report.surfaces.map((e) => e.toJson()).toList(),
        'SHOW RESIDUALS' => {
          for (final e in report.surfaces) e.id: e.residuals.toJson(),
        },
        'SHOW FIT REPORT' => report.toJson(),
        'SHOW FIT ANALYTICS' => report.analytics.toJson(),
        'SHOW FAILED FITS' =>
          report.surfaces
              .where((e) => e.handle == null)
              .map((e) => e.toJson())
              .toList(),
        'SHOW RMS' => {for (final e in report.surfaces) e.id: e.residuals.rms},
        'SHOW CONFIDENCE' => {
          for (final e in report.surfaces) e.id: e.confidence,
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

List<FELCommand> createSurfaceFittingFelCommands(
  SurfaceFittingApi api,
  MeshEntity? Function() mesh,
  SurfaceRecognitionReport? Function() recognition,
) {
  const required = [
    'RUN SURFACE FITTING',
    'FIT PLANES',
    'FIT CYLINDERS',
    'FIT CONES',
    'FIT SPHERES',
    'FIT TORI',
    'SHOW SURFACES',
    'SHOW RESIDUALS',
    'SHOW SURFACE TREE',
    'SHOW FIT REPORT',
    'SHOW FIT ANALYTICS',
    'SHOW FAILED FITS',
    'SHOW RMS',
    'SHOW CONFIDENCE',
  ];
  const subjects = [
    'SURFACE',
    'PLANE',
    'CYLINDER',
    'CONE',
    'SPHERE',
    'TORUS',
    'FIT',
    'RESIDUAL',
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
    'SHOW PARAMETERS',
    'SHOW RMS',
    'SHOW MAX ERROR',
    'SHOW MEAN ERROR',
    'SHOW HEALTH',
    'SHOW HISTORY',
    'SHOW STATISTICS',
    'ACCEPT',
    'REJECT',
    'REFIT',
  ];
  final names = <String>{
    ...required,
    for (final subject in subjects)
      for (final operation in operations) '$operation $subject',
  };
  return [
    for (final name in names)
      SurfaceFittingFelCommand(name, api, mesh, recognition),
  ];
}
