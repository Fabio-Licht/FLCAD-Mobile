import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/surface_recognition/api/surface_recognition_api.dart';
import 'package:flcad_mobile/core/surface_recognition/engine/surface_recognition_engine.dart';
import 'package:flcad_mobile/core/surface_recognition/integration/recognition_workspace.dart';
import 'package:flcad_mobile/core/surface_recognition/integration/surface_recognition_integration.dart';
import 'package:flcad_mobile/core/surface_recognition/repository/surface_recognition_repository.dart';
import 'package:flcad_mobile/core/surface_recognition/validation/surface_recognition_validation.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/surface_recognition_certification.dart <dll> <bearing.stl> <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final projectDirectory = Directory(args[2]);
  await projectDirectory.create(recursive: true);
  final kernel = OpenCascadeKernelAdapter(
    bridge: OpenCascadeFFI.load(path: args[0]),
  );
  final health = await kernel.healthCheck();
  if (health.status.name != 'healthy') {
    throw StateError(health.message);
  }
  final meshApi = const MeshFactory().create(
    projectDirectory: projectDirectory,
    kernel: kernel,
  );
  final imported = await meshApi.importStl(args[1], projectId: 'g010b-bearing');
  final project = <String, dynamic>{'activeMesh': imported.mesh.toJson()},
      dashboard = <String, dynamic>{},
      session = <String, dynamic>{'workflowStage': 'recognition'};
  final api = SurfaceRecognitionApi(
    SurfaceRecognitionEngine(
      kernel: kernel,
      repository: SurfaceRecognitionRepository(projectDirectory),
      integration: OfficialSurfaceRecognitionIntegration(
        project: project,
        dashboard: dashboard,
        session: session,
      ),
    ),
  );
  final report = await api.run(imported.mesh);
  final errors = const SurfaceRecognitionValidation().validate(report);
  if (errors.isNotEmpty) throw StateError(errors.join('; '));
  final workspace = RecognitionWorkspace(report);
  workspace.select(report.classifications.first.region.id);
  if (workspace.propertyInspector['Recognition Type'] == null) {
    throw StateError('Property Inspector is not synchronized');
  }
  await api.persist();
  final certificate = {
    'sprint': 'G-010B',
    'status': 'APPROVED',
    'backend': 'OpenCascade',
    'nativeType': 'Poly_Triangulation',
    'mesh': imported.mesh.toJson(),
    'report': report.toJson(),
    'workspace': {
      'panels': [
        'Recognition Tree',
        'Recognition Properties',
        'Confidence Map',
        'Region Statistics',
        'Recognition Analytics',
        'Recognition Advisor',
        'Recognition Timeline',
      ],
      'propertyInspector': workspace.propertyInspector,
    },
    'integration': {
      'project': project,
      'dashboard': dashboard,
      'session': session,
    },
    'noCadCreated': true,
  };
  await File(
    '${projectDirectory.path}${Platform.pathSeparator}G010B-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Surface Recognition: APPROVED');
  stdout.writeln('OpenCascade: ${kernel.descriptor.version}');
  stdout.writeln(
    'Mesh: ${imported.mesh.vertexCount} vertices / ${imported.mesh.triangleCount} triangles',
  );
  stdout.writeln('Regions: ${report.classifications.length}');
  stdout.writeln('Distribution: ${report.analytics.toJson()['distribution']}');
  stdout.writeln(
    'Average confidence: ${(report.analytics.averageConfidence * 100).toStringAsFixed(2)}%',
  );
  stdout.writeln('Creates CAD: false');
  await meshApi.close(imported.mesh.id);
  await kernel.unload();
}
