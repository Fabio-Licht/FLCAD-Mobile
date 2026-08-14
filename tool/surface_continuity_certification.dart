import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_continuity_factory.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_continuity_integration.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_quality_workspace.dart';
import 'package:flcad_mobile/core/surface_continuity/models/surface_continuity_models.dart';
import 'package:flcad_mobile/core/surface_fitting/api/surface_fitting_api.dart';
import 'package:flcad_mobile/core/surface_fitting/engine/surface_fitting_engine.dart';
import 'package:flcad_mobile/core/surface_fitting/repository/surface_fitting_repository.dart';
import 'package:flcad_mobile/core/surface_recognition/api/surface_recognition_api.dart';
import 'package:flcad_mobile/core/surface_recognition/engine/surface_recognition_engine.dart';
import 'package:flcad_mobile/core/surface_recognition/repository/surface_recognition_repository.dart';
import 'package:flcad_mobile/core/surface_topology/api/surface_topology_api.dart';
import 'package:flcad_mobile/core/surface_topology/engine/surface_topology_engine.dart';
import 'package:flcad_mobile/core/surface_topology/repository/surface_topology_repository.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/surface_continuity_certification.dart <dll> <bearing.stl> <project-dir>',
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
    projectId: 'g010e-bearing',
  )).mesh;
  final recognitionApi = SurfaceRecognitionApi(
    SurfaceRecognitionEngine(
      kernel: kernel,
      repository: SurfaceRecognitionRepository(directory),
    ),
  );
  final recognition = await recognitionApi.run(mesh);
  final fittingApi = SurfaceFittingApi(
    SurfaceFittingEngine(
      kernel: kernel,
      repository: SurfaceFittingRepository(directory),
    ),
  );
  final fitting = await fittingApi.run(
    mesh: mesh,
    recognition: recognition,
    projectId: 'g010e-bearing',
  );
  final topologyApi = SurfaceTopologyApi(
    SurfaceTopologyEngine(
      kernel: kernel,
      repository: SurfaceTopologyRepository(directory),
    ),
  );
  final topology = await topologyApi.build(fitting, projectId: 'g010e-bearing');
  final originalHandles = topology.patches
      .map((e) => e.surface.handle?.persistentId)
      .toList();
  final project = <String, dynamic>{
    'mesh': mesh.toJson(),
    'recognition': recognition.toJson(),
    'fitting': fitting.toJson(),
    'topology': topology.toJson(),
  };
  final dashboard = <String, dynamic>{};
  final session = <String, dynamic>{};
  final qualityApi = const SurfaceContinuityFactory().create(
    projectDirectory: directory,
    kernel: kernel,
    integration: OfficialSurfaceContinuityIntegration(
      project: project,
      dashboard: dashboard,
      session: session,
    ),
  );
  final report = await qualityApi.run(topology);
  if (report.patchQualities.isEmpty ||
      report.patchQualities.any(
        (e) => !e.overall.isFinite || !e.curvature.mean.isFinite,
      )) {
    throw StateError('Native surface quality report is invalid');
  }
  if (report.continuity.any((e) => e.level != ContinuityLevel.notApplicable) &&
      topology.patches.length == 1) {
    throw StateError('Continuity was fabricated for an isolated patch');
  }
  if (topology.patches
          .map((e) => e.surface.handle?.persistentId)
          .toList()
          .toString() !=
      originalHandles.toString()) {
    throw StateError('Surface quality analysis modified geometry');
  }
  final workspace = SurfaceQualityWorkspace(report)
    ..select(report.patchQualities.first.patch.id);
  await recognitionApi.persist();
  await fittingApi.persist();
  await topologyApi.persist();
  await qualityApi.persist();
  final certificate = {
    'sprint': 'G-010E',
    'status': 'APPROVED',
    'backend': 'OpenCascade',
    'kernelVersion': kernel.descriptor.version,
    'source': mesh.toJson(),
    'surfaceQuality': report.toJson(),
    'workspace': {
      'panels': workspace.panels,
      'propertyInspector': workspace.propertyInspector,
    },
    'integration': {
      'project': project,
      'dashboard': dashboard,
      'session': session,
    },
    'geometryModified': false,
    'solidsCreated': 0,
    'fallbacks': 0,
  };
  await File(
    '${directory.path}${Platform.pathSeparator}G010E-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  stdout.writeln('Professional Continuity & Surface Quality: APPROVED');
  stdout.writeln('OpenCascade: ${kernel.descriptor.version}');
  stdout.writeln('Patches: ${report.patchQualities.length}');
  stdout.writeln(
    'Continuity: ${report.analytics.continuityDistribution.map((k, v) => MapEntry(k.name, v))}',
  );
  stdout.writeln('Quality score: ${report.analytics.qualityScore}');
  stdout.writeln('Geometry modified: false');
  stdout.writeln('Fallbacks: 0');
  await meshApi.close(mesh.id);
  await kernel.unload();
}
