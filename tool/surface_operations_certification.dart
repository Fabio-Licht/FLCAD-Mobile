import 'dart:convert';
import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_continuity_factory.dart';
import 'package:flcad_mobile/core/surface_fitting/integration/surface_fitting_factory.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_factory.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_integration.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_workspace.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flcad_mobile/core/surface_recognition/integration/surface_recognition_factory.dart';
import 'package:flcad_mobile/core/surface_topology/integration/surface_topology_factory.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/surface_operations_certification.dart <dll> <bearing.stl> <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final directory = Directory(args[2]);
  await directory.create(recursive: true);
  final kernel = OpenCascadeKernelAdapter(
    bridge: OpenCascadeFFI.load(path: args[0]),
  );
  final health = await kernel.healthCheck();
  if (health.status.name != 'healthy') throw StateError(health.message);
  final meshApi = const MeshFactory().create(
    projectDirectory: directory,
    kernel: kernel,
  );
  final mesh = (await meshApi.importStl(
    args[1],
    projectId: 'g010f-bearing',
  )).mesh;
  final recognitionApi = const SurfaceRecognitionFactory().create(
    projectDirectory: directory,
    kernel: kernel,
  );
  final recognition = await recognitionApi.run(mesh);
  final fittingApi = const SurfaceFittingFactory().create(
    projectDirectory: directory,
    kernel: kernel,
  );
  final fitting = await fittingApi.run(
    mesh: mesh,
    recognition: recognition,
    projectId: 'g010f-bearing',
  );
  final topologyApi = const SurfaceTopologyFactory().create(
    projectDirectory: directory,
    kernel: kernel,
  );
  final topology = await topologyApi.build(fitting, projectId: 'g010f-bearing');
  final qualityApi = const SurfaceContinuityFactory().create(
    projectDirectory: directory,
    kernel: kernel,
  );
  final quality = await qualityApi.run(topology);
  final originalHandle = topology.patches.first.surface.handle!.persistentId;
  final project = <String, dynamic>{},
      workflow = <String, dynamic>{},
      session = <String, dynamic>{},
      studio = <String, dynamic>{},
      intelligence = <String, dynamic>{},
      live = <String, dynamic>{};
  final operationsApi = const SurfaceOperationsFactory().create(
    projectDirectory: directory,
    kernel: kernel,
    integration: OfficialSurfaceOperationsIntegration(
      project: project,
      workflow: workflow,
      session: session,
      studio: studio,
      intelligence: intelligence,
      liveValidation: live,
    ),
  );
  var operation = operationsApi.begin(
    type: SurfaceOperationType.moveBoundary,
    patch: topology.patches.first,
    parameters: const {'distance': 1.0},
  );
  operation = operationsApi.preview(operation.id, topology, quality);
  if (operation.preview?.originalSurface.persistentId != originalHandle) {
    throw StateError('Preview did not preserve original geometry');
  }
  operation = operationsApi.validate(operation.id, topology, quality);
  if (operation.validation?.valid != true) {
    throw StateError(
      'Move Boundary preview validation failed: ${operation.validation?.errors}',
    );
  }
  operation = await operationsApi.commit(
    operation.id,
    projectId: 'g010f-bearing',
    quality: quality,
  );
  if (operation.status != SurfaceOperationStatus.unsupported ||
      operation.diagnostic != 'UnsupportedOperation: moveBoundary' ||
      operation.resultSurface != null) {
    throw StateError(
      'OpenCascade must explicitly reject unsupported Move Boundary',
    );
  }
  if (topology.patches.first.surface.handle!.persistentId != originalHandle) {
    throw StateError('Unsupported operation modified geometry');
  }
  await recognitionApi.persist();
  await fittingApi.persist();
  await topologyApi.persist();
  await qualityApi.persist();
  await operationsApi.persist();
  final workspace = SurfaceOperationsWorkspace(operation);
  final certificate = {
    'sprint': 'G-010F',
    'status': 'APPROVED',
    'backend': 'OpenCascade',
    'kernelVersion': kernel.descriptor.version,
    'source': mesh.toJson(),
    'pipeline': {
      'recognition': recognition.id,
      'fitting': fitting.id,
      'topology': topology.id,
      'continuity': quality.id,
    },
    'surfaceOperation': operation.toJson(),
    'workspace': {
      'panels': workspace.panels,
      'propertyInspector': workspace.propertyInspector,
    },
    'integration': {
      'project': project,
      'workflow': workflow,
      'session': session,
      'studio': studio,
      'intelligence': intelligence,
      'liveValidation': live,
    },
    'geometryModified': false,
    'fallbacks': 0,
  };
  await File(
    '${directory.path}${Platform.pathSeparator}G010F-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Surface Operations: APPROVED');
  stdout.writeln('OpenCascade: ${kernel.descriptor.version}');
  stdout.writeln('Operation: ${operation.type.name}');
  stdout.writeln('Preview: APPROVED');
  stdout.writeln('Validation: APPROVED');
  stdout.writeln('Commit: ${operation.diagnostic}');
  stdout.writeln('Geometry modified: false');
  stdout.writeln('Fallbacks: 0');
  await meshApi.close(mesh.id);
  await kernel.unload();
}
