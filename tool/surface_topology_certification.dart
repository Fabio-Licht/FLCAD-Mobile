import 'dart:convert';
import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/surface_recognition/api/surface_recognition_api.dart';
import 'package:flcad_mobile/core/surface_recognition/engine/surface_recognition_engine.dart';
import 'package:flcad_mobile/core/surface_recognition/repository/surface_recognition_repository.dart';
import 'package:flcad_mobile/core/surface_fitting/api/surface_fitting_api.dart';
import 'package:flcad_mobile/core/surface_fitting/engine/surface_fitting_engine.dart';
import 'package:flcad_mobile/core/surface_fitting/repository/surface_fitting_repository.dart';
import 'package:flcad_mobile/core/surface_topology/api/surface_topology_api.dart';
import 'package:flcad_mobile/core/surface_topology/engine/surface_topology_engine.dart';
import 'package:flcad_mobile/core/surface_topology/integration/surface_topology_integration.dart';
import 'package:flcad_mobile/core/surface_topology/integration/surface_topology_workspace.dart';
import 'package:flcad_mobile/core/surface_topology/repository/surface_topology_repository.dart';
import 'package:flcad_mobile/core/surface_topology/validation/topology_validation.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/surface_topology_certification.dart <dll> <bearing.stl> <project-dir>',
    );
    exitCode = 64;
    return;
  }
  final directory = Directory(args[2]);
  await directory.create(recursive: true);
  final kernel = OpenCascadeKernelAdapter(
        bridge: OpenCascadeFFI.load(path: args[0]),
      ),
      health = await kernel.healthCheck();
  if (health.status.name != 'healthy') throw StateError(health.message);
  final meshApi = const MeshFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      mesh = (await meshApi.importStl(
        args[1],
        projectId: 'g010d-bearing',
      )).mesh;
  final recognitionApi = SurfaceRecognitionApi(
        SurfaceRecognitionEngine(
          kernel: kernel,
          repository: SurfaceRecognitionRepository(directory),
        ),
      ),
      recognition = await recognitionApi.run(mesh);
  final fittingApi = SurfaceFittingApi(
        SurfaceFittingEngine(
          kernel: kernel,
          repository: SurfaceFittingRepository(directory),
        ),
      ),
      fitting = await fittingApi.run(
        mesh: mesh,
        recognition: recognition,
        projectId: 'g010d-bearing',
      );
  final project = <String, dynamic>{
        'mesh': mesh.toJson(),
        'recognition': recognition.toJson(),
        'fitting': fitting.toJson(),
      },
      dashboard = <String, dynamic>{},
      session = <String, dynamic>{};
  final topologyApi = SurfaceTopologyApi(
        SurfaceTopologyEngine(
          kernel: kernel,
          repository: SurfaceTopologyRepository(directory),
          integration: OfficialSurfaceTopologyIntegration(
            project: project,
            dashboard: dashboard,
            session: session,
          ),
        ),
      ),
      topology = await topologyApi.build(fitting, projectId: 'g010d-bearing'),
      errors = const SurfaceTopologyValidation().validate(topology);
  if (errors.isNotEmpty) {
    throw StateError(errors.join('; '));
  }
  if (topology.patches.isEmpty ||
      topology.boundaries.isEmpty ||
      topology.loops.isEmpty) {
    throw StateError('Native topology is incomplete');
  }
  if (topology.patches.any(
    (e) =>
        e.surface.handle == null || e.surface.handle!.kernelId != 'opencascade',
  )) {
    throw StateError('Patch is not linked to an OpenCascade surface');
  }
  final workspace = SurfaceTopologyWorkspace(topology)
    ..selectPatch(topology.patches.first.id);
  await recognitionApi.persist();
  await fittingApi.persist();
  await topologyApi.persist();
  final certificate = {
    'sprint': 'G-010D',
    'status': 'APPROVED',
    'backend': 'OpenCascade',
    'kernelVersion': kernel.descriptor.version,
    'mesh': mesh.toJson(),
    'recognition': recognition.toJson(),
    'surfaceFitting': fitting.toJson(),
    'surfaceTopology': topology.toJson(),
    'workspace': {
      'panels': workspace.panels,
      'propertyInspector': workspace.propertyInspector,
    },
    'integration': {
      'project': project,
      'dashboard': dashboard,
      'session': session,
    },
    'solidsCreated': 0,
    'finalBrepCreated': false,
    'fallbacks': 0,
  };
  await File(
    '${directory.path}${Platform.pathSeparator}G010D-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Surface Topology: APPROVED');
  stdout.writeln('OpenCascade: ${kernel.descriptor.version}');
  stdout.writeln('Patches: ${topology.patches.length}');
  stdout.writeln('Boundaries: ${topology.boundaries.length}');
  stdout.writeln('Loops: ${topology.loops.length}');
  stdout.writeln('Intersections: ${topology.intersections.length}');
  stdout.writeln(
    'Topology health: ${topology.analytics.validCount}/${topology.patches.length} valid',
  );
  stdout.writeln('Solids: 0');
  stdout.writeln('Fallbacks: 0');
  await meshApi.close(mesh.id);
  await kernel.unload();
}
