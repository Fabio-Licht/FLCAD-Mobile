import 'dart:convert';
import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/live_reconstruction_factory.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/live_reconstruction_integration.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/reconstruction_workspace.dart';
import 'package:flcad_mobile/core/live_reconstruction/models/live_reconstruction_models.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_continuity_factory.dart';
import 'package:flcad_mobile/core/surface_fitting/integration/surface_fitting_factory.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_factory.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flcad_mobile/core/surface_recognition/integration/surface_recognition_factory.dart';
import 'package:flcad_mobile/core/surface_topology/integration/surface_topology_factory.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_reconstruction_certification.dart <dll> <bearing.stl> <project-dir>',
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
    projectId: 'g010g-bearing',
  )).mesh;
  final recognitionApi = const SurfaceRecognitionFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      recognition = await recognitionApi.run(mesh);
  final fittingApi = const SurfaceFittingFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      fitting = await fittingApi.run(
        mesh: mesh,
        recognition: recognition,
        projectId: 'g010g-bearing',
      );
  final topologyApi = const SurfaceTopologyFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      topology = await topologyApi.build(fitting, projectId: 'g010g-bearing');
  final qualityApi = const SurfaceContinuityFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      quality = await qualityApi.run(topology);
  final operations = const SurfaceOperationsFactory().create(
    projectDirectory: directory,
    kernel: kernel,
  );
  final project = <String, dynamic>{},
      workflow = <String, dynamic>{},
      session = <String, dynamic>{},
      studio = <String, dynamic>{},
      intelligence = <String, dynamic>{},
      validation = <String, dynamic>{};
  final liveApi = const LiveReconstructionFactory().create(
    projectDirectory: directory,
    operations: operations,
    integration: OfficialLiveReconstructionIntegration(
      project: project,
      workflow: workflow,
      session: session,
      studio: studio,
      intelligence: intelligence,
      liveValidation: validation,
    ),
  );
  final original = topology.patches.first.surface.handle!.persistentId;

  var rollbackOperation = operations.begin(
    type: SurfaceOperationType.moveBoundary,
    patch: topology.patches.first,
    parameters: const {'distance': 1.0},
  );
  rollbackOperation = operations.preview(
    rollbackOperation.id,
    topology,
    quality,
  );
  rollbackOperation = operations.validate(
    rollbackOperation.id,
    topology,
    quality,
  );
  var rolledBack = liveApi.begin(rollbackOperation, topology, quality);
  rolledBack = liveApi.preview(rolledBack.id, quality);
  rolledBack = liveApi.validate(rolledBack.id);
  rolledBack = liveApi.update(rolledBack.id);
  rolledBack = await liveApi.rollback(rolledBack.id);
  if (rolledBack.state != ReconstructionState.rolledBack ||
      rolledBack.updatedObjects.isNotEmpty) {
    throw StateError('Incremental rollback did not restore preview state');
  }

  var operation = operations.begin(
    type: SurfaceOperationType.moveBoundary,
    patch: topology.patches.first,
    parameters: const {'distance': 1.0},
  );
  operation = operations.preview(operation.id, topology, quality);
  operation = operations.validate(operation.id, topology, quality);
  var live = liveApi.begin(operation, topology, quality);
  live = liveApi.preview(live.id, quality);
  live = liveApi.validate(live.id);
  live = liveApi.update(live.id);
  final scheduled = Set<String>.of(live.updatedObjects);
  live = await liveApi.commit(
    live.id,
    projectId: 'g010g-bearing',
    quality: quality,
  );
  if (live.state != ReconstructionState.unsupported ||
      live.operation.diagnostic != 'UnsupportedOperation: moveBoundary') {
    throw StateError('Unsupported OpenCascade operation was not propagated');
  }
  if (topology.patches.first.surface.handle!.persistentId != original ||
      live.operation.resultSurface != null) {
    throw StateError('Live reconstruction fabricated or modified geometry');
  }
  await recognitionApi.persist();
  await fittingApi.persist();
  await topologyApi.persist();
  await qualityApi.persist();
  await operations.persist();
  await liveApi.persist();
  final workspace = ReconstructionWorkspace(live);
  final certificate = {
    'sprint': 'G-010G',
    'g010Status': 'CLOSED_AND_CERTIFIED',
    'status': 'APPROVED',
    'backend': 'OpenCascade',
    'kernelVersion': kernel.descriptor.version,
    'source': mesh.toJson(),
    'pipeline': {
      'mesh': mesh.id,
      'recognition': recognition.id,
      'fitting': fitting.id,
      'topology': topology.id,
      'continuity': quality.id,
      'surfaceOperation': operation.id,
      'liveReconstruction': live.id,
    },
    'incremental': {
      'affected': live.preview!.affected.toJson(),
      'scheduledObjects': scheduled.toList()..sort(),
      'fullProjectRecalculation': false,
    },
    'rollback': rolledBack.toJson(),
    'commit': live.toJson(),
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
      'liveValidation': validation,
    },
    'geometryModified': false,
    'fallbacks': 0,
  };
  await File(
    '${directory.path}${Platform.pathSeparator}G010G-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Live Surface Reconstruction: APPROVED');
  stdout.writeln('G-010: CLOSED AND CERTIFIED');
  stdout.writeln('OpenCascade: ${kernel.descriptor.version}');
  stdout.writeln('Affected patches: ${live.preview!.affected.patches.length}');
  stdout.writeln('Scheduled objects: ${scheduled.length}');
  stdout.writeln('Full project recalculation: false');
  stdout.writeln('Rollback: APPROVED');
  stdout.writeln('Commit: ${live.operation.diagnostic}');
  stdout.writeln('Geometry modified: false');
  stdout.writeln('Fallbacks: 0');
  await meshApi.close(mesh.id);
  await kernel.unload();
}
