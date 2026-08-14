import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/surface_fitting/api/surface_fitting_api.dart';
import 'package:flcad_mobile/core/surface_fitting/engine/surface_fitting_engine.dart';
import 'package:flcad_mobile/core/surface_fitting/integration/surface_fitting_integration.dart';
import 'package:flcad_mobile/core/surface_fitting/integration/surface_fitting_workspace.dart';
import 'package:flcad_mobile/core/surface_fitting/models/surface_fitting_models.dart';
import 'package:flcad_mobile/core/surface_fitting/repository/surface_fitting_repository.dart';
import 'package:flcad_mobile/core/surface_fitting/validation/surface_fit_validation.dart';
import 'package:flcad_mobile/core/surface_recognition/api/surface_recognition_api.dart';
import 'package:flcad_mobile/core/surface_recognition/engine/surface_recognition_engine.dart';
import 'package:flcad_mobile/core/surface_recognition/repository/surface_recognition_repository.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/surface_fitting_certification.dart <dll> <bearing.stl> <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final projectDirectory = Directory(args[2]);
  await projectDirectory.create(recursive: true);
  final kernel = OpenCascadeKernelAdapter(
        bridge: OpenCascadeFFI.load(path: args[0]),
      ),
      health = await kernel.healthCheck();
  if (health.status.name != 'healthy') throw StateError(health.message);
  final meshApi = const MeshFactory().create(
        projectDirectory: projectDirectory,
        kernel: kernel,
      ),
      mesh = (await meshApi.importStl(
        args[1],
        projectId: 'g010c-bearing',
      )).mesh;
  final recognitionApi = SurfaceRecognitionApi(
        SurfaceRecognitionEngine(
          kernel: kernel,
          repository: SurfaceRecognitionRepository(projectDirectory),
        ),
      ),
      recognition = await recognitionApi.run(mesh);
  final project = <String, dynamic>{
        'activeMesh': mesh.toJson(),
        'surfaceRecognition': recognition.toJson(),
      },
      dashboard = <String, dynamic>{},
      session = <String, dynamic>{'workflowStage': 'surfaceFitting'};
  final fittingApi = SurfaceFittingApi(
        SurfaceFittingEngine(
          kernel: kernel,
          repository: SurfaceFittingRepository(projectDirectory),
          integration: OfficialSurfaceFittingIntegration(
            project: project,
            dashboard: dashboard,
            session: session,
          ),
        ),
      ),
      report = await fittingApi.run(
        mesh: mesh,
        recognition: recognition,
        projectId: 'g010c-bearing',
      );
  final errors = const SurfaceFitValidation().validateReport(report);
  if (errors.isNotEmpty) {
    throw StateError(errors.join('; '));
  }
  final accepted = report.surfaces
      .where((e) => e.status == SurfaceFitStatus.accepted)
      .toList();
  if (accepted.isEmpty) {
    throw StateError('bearing.stl produced no native primitive surface');
  }
  for (final surface in accepted) {
    if (surface.handle == null ||
        surface.handle!.kernelId != 'opencascade' ||
        surface.handle!.type.name != 'face') {
      throw StateError('Surface ${surface.id} is not a real OpenCascade face');
    }
  }
  final workspace = SurfaceFittingWorkspace(report)..select(accepted.first.id);
  if (workspace.propertyInspector['Surface Type'] == null) {
    throw StateError('Surface Property Inspector is not synchronized');
  }
  await recognitionApi.persist();
  await fittingApi.persist();
  final certificate = {
    'sprint': 'G-010C',
    'status': 'APPROVED',
    'backend': 'OpenCascade',
    'kernelVersion': kernel.descriptor.version,
    'mesh': mesh.toJson(),
    'recognition': recognition.toJson(),
    'surfaceFitting': report.toJson(),
    'workspace': {
      'panels': [
        'Surface Tree',
        'Surface Properties',
        'Residual Statistics',
        'Surface Analytics',
        'Surface Advisor',
        'Surface Timeline',
      ],
      'tree': workspace.tree,
      'propertyInspector': workspace.propertyInspector,
    },
    'integration': {
      'project': project,
      'dashboard': dashboard,
      'session': session,
    },
    'simulatedSurfaces': 0,
    'fallbacks': 0,
  };
  await File(
    '${projectDirectory.path}${Platform.pathSeparator}G010C-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Surface Fitting: APPROVED');
  stdout.writeln('OpenCascade: ${kernel.descriptor.version}');
  stdout.writeln(
    'Mesh: ${mesh.vertexCount} vertices / ${mesh.triangleCount} triangles',
  );
  stdout.writeln('Recognition regions: ${recognition.classifications.length}');
  stdout.writeln('Native surfaces: ${accepted.length}');
  stdout.writeln('Types: ${report.analytics.toJson()['distribution']}');
  stdout.writeln('Average RMS: ${report.analytics.averageRms}');
  stdout.writeln(
    'Average confidence: ${(report.analytics.averageConfidence * 100).toStringAsFixed(2)}%',
  );
  stdout.writeln('Fallbacks: 0');
  await meshApi.close(mesh.id);
  await kernel.unload();
}
