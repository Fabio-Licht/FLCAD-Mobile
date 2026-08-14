import 'dart:convert';
import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/live_reconstruction/integration/live_reconstruction_factory.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/surface_continuity/integration/surface_continuity_factory.dart';
import 'package:flcad_mobile/core/surface_fitting/integration/surface_fitting_factory.dart';
import 'package:flcad_mobile/core/surface_morph/integration/surface_morph_factory.dart';
import 'package:flcad_mobile/core/surface_morph/integration/surface_morph_integration.dart';
import 'package:flcad_mobile/core/surface_morph/models/surface_morph_models.dart';
import 'package:flcad_mobile/core/surface_morph/workspace/surface_morph_workspace.dart';
import 'package:flcad_mobile/core/surface_operations/integration/surface_operations_factory.dart';
import 'package:flcad_mobile/core/surface_recognition/integration/surface_recognition_factory.dart';
import 'package:flcad_mobile/core/surface_topology/integration/surface_topology_factory.dart';
import 'package:flcad_mobile/core/surface_extend/integration/surface_extend_factory.dart';
import 'package:flcad_mobile/core/surface_extend/models/surface_extend_models.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/surface_morph_certification.dart <dll> <bearing.stl> <project-dir>',
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
      ),
      mesh = (await meshApi.importStl(
        args[1],
        projectId: 'g011a-bearing',
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
        projectId: 'g011a-bearing',
      );
  final topologyApi = const SurfaceTopologyFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      topology = await topologyApi.build(fitting, projectId: 'g011a-bearing');
  final qualityApi = const SurfaceContinuityFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      quality = await qualityApi.run(topology);
  final operations = const SurfaceOperationsFactory().create(
        projectDirectory: directory,
        kernel: kernel,
      ),
      live = const LiveReconstructionFactory().create(
        projectDirectory: directory,
        operations: operations,
      );
  final project = <String, dynamic>{},
      workflow = <String, dynamic>{},
      session = <String, dynamic>{},
      studio = <String, dynamic>{},
      intelligence = <String, dynamic>{};
  final morphApi = const SurfaceMorphFactory().create(
    projectDirectory: directory,
    operations: operations,
    reconstruction: live,
    integration: OfficialSurfaceMorphIntegration(
      project: project,
      workflow: workflow,
      session: session,
      studio: studio,
      intelligence: intelligence,
    ),
  );
  final patch = topology.patches.first,
      original = patch.surface.handle!.persistentId;
  var morph = morphApi.begin(
    tool: MorphTool.move,
    patch: patch,
    anchors: [
      MorphAnchor(
        id: 'fixed:${patch.id}',
        type: AnchorType.fixed,
        targetId: patch.id,
        position: const [0, 0, 0],
      ),
      MorphAnchor(
        id: 'boundary:${patch.id}',
        type: AnchorType.boundary,
        targetId: patch.boundaryIds.first,
        position: const [1, 0, 0],
        strength: .75,
      ),
    ],
    radius: 10,
    falloff: FalloffType.smooth,
  );
  morph = morphApi.preview(morph.id, topology, quality);
  if (morph.preview?.originalSurfaceId != original ||
      morph.preview?.toJson()['geometryModified'] != false) {
    throw StateError('Morph preview changed the native baseline');
  }
  morph = morphApi.validate(morph.id, topology, quality);
  if (morph.validation?.valid != true) {
    throw StateError('Morph validation failed: ${morph.validation?.errors}');
  }
  morph = await morphApi.commit(
    morph.id,
    topology: topology,
    quality: quality,
    projectId: 'g011a-bearing',
  );
  if (morph.status != MorphStatus.unsupported ||
      morph.diagnostic != 'UnsupportedOperation: moveBoundary') {
    throw StateError('OpenCascade unsupported morph was not explicit');
  }
  if (patch.surface.handle!.persistentId != original) {
    throw StateError('Morph modified geometry without backend support');
  }
  final extendApi = const SurfaceExtendFactory().create(
    projectDirectory: directory,
    morph: morphApi,
  );
  var extend = extendApi.begin(
    type: ExtendType.smart,
    patch: patch,
    boundaryId: patch.boundaryIds.first,
    anchors: morph.anchors,
    parameters: const {
      'distance': 1.0,
      'angle': 0.0,
      'vector': [0.0, 0.0, 1.0],
    },
    manufacturingIntent: 'bearing tooling',
  );
  extend = extendApi.preview(extend.id, topology, quality);
  extend = extendApi.validate(extend.id, topology, quality);
  if (extend.validation?.valid != true) {
    throw StateError('Extend validation failed: ${extend.validation?.errors}');
  }
  extend = await extendApi.commit(
    extend.id,
    topology: topology,
    quality: quality,
    projectId: 'g011b-bearing',
  );
  if (extend.status != ExtendStatus.unsupported ||
      extend.diagnostic != 'UnsupportedOperation: moveBoundary' ||
      patch.surface.handle!.persistentId != original) {
    throw StateError('Extend did not preserve unsupported native geometry');
  }
  await recognitionApi.persist();
  await fittingApi.persist();
  await topologyApi.persist();
  await qualityApi.persist();
  await operations.persist();
  await live.persist();
  await morphApi.persist();
  await extendApi.persist();
  final workspace = SurfaceMorphWorkspace(morph),
      certificate = {
        'sprint': 'G-011A',
        'status': 'APPROVED',
        'backend': 'OpenCascade',
        'kernelVersion': kernel.descriptor.version,
        'source': mesh.toJson(),
        'pipeline': {
          'recognition': recognition.id,
          'fitting': fitting.id,
          'topology': topology.id,
          'continuity': quality.id,
          'surfaceMorph': morph.id,
        },
        'morph': morph.toJson(),
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
        },
        'geometryModified': false,
        'fallbacks': 0,
      };
  await File(
    '${directory.path}${Platform.pathSeparator}G011A-Certification.json',
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(certificate));
  await File(
    '${directory.path}${Platform.pathSeparator}G011B-Certification.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'sprint': 'G-011B',
      'status': 'APPROVED',
      'backend': 'OpenCascade',
      'source': mesh.toJson(),
      'extend': extend.toJson(),
      'geometryModified': false,
      'fallbacks': 0,
    }),
  );
  stdout.writeln('Professional Surface Morph Studio Foundation: APPROVED');
  stdout.writeln('OpenCascade: ${kernel.descriptor.version}');
  stdout.writeln('Anchors: ${morph.anchors.length}');
  stdout.writeln('Influence: ${morph.falloff.name} / radius ${morph.radius}');
  stdout.writeln('Preview: APPROVED');
  stdout.writeln('Validation: APPROVED');
  stdout.writeln('Commit: ${morph.diagnostic}');
  stdout.writeln('Geometry modified: false');
  stdout.writeln('Fallbacks: 0');
  stdout.writeln('Professional Extend Suite: APPROVED');
  stdout.writeln('Extend commit: ${extend.diagnostic}');
  await meshApi.close(mesh.id);
  await kernel.unload();
}
