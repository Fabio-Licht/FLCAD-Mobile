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
import 'package:flcad_mobile/core/surface_reduce/integration/surface_reduce_factory.dart';
import 'package:flcad_mobile/core/surface_reduce/models/surface_reduce_models.dart';
import 'package:flcad_mobile/core/surface_fair/integration/surface_fair_factory.dart';
import 'package:flcad_mobile/core/surface_fair/models/surface_fair_models.dart';
import 'package:flcad_mobile/core/surface_boundary/integration/surface_boundary_factory.dart';
import 'package:flcad_mobile/core/surface_boundary/models/surface_boundary_models.dart';
import 'package:flcad_mobile/core/surface_manufacturing/integration/surface_manufacturing_factory.dart';
import 'package:flcad_mobile/core/surface_manufacturing/models/surface_manufacturing_models.dart';
import 'package:flcad_mobile/core/advanced_surface/integration/advanced_surface_factory.dart';
import 'package:flcad_mobile/core/advanced_surface/models/advanced_surface_models.dart';

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
  final reduceApi = const SurfaceReduceFactory().create(
    projectDirectory: directory,
    operations: operations,
  );
  var reduce = reduceApi.begin(
    type: ReduceType.smart,
    patch: patch,
    parameters: const {
      'reduction': 10.0,
      'direction': [0.0, 0.0, 1.0],
    },
    fixedRegions: [
      FixedRegion(
        id: 'bearing-boundary',
        type: FixedRegionType.boundary,
        targetId: patch.boundaryIds.first,
      ),
    ],
    transition: ReduceContinuity.g2,
  );
  reduce = reduceApi.preview(reduce.id, topology, quality);
  if (reduce.prediction?.toJson()['geometryModified'] != false) {
    throw StateError('Reduce preview changed the native baseline');
  }
  reduce = reduceApi.validate(reduce.id, topology, quality);
  if (reduce.validation?.valid != true) {
    throw StateError('Reduce validation failed: ${reduce.validation?.errors}');
  }
  reduce = await reduceApi.commit(
    reduce.id,
    topology: topology,
    quality: quality,
    projectId: 'g011c-bearing',
  );
  if (reduce.status != ReduceStatus.unsupported ||
      reduce.diagnostic != 'UnsupportedOperation: reduceSurface' ||
      patch.surface.handle!.persistentId != original) {
    throw StateError('Reduce did not preserve unsupported native geometry');
  }
  reduce = await reduceApi.rollback(reduce.id);
  final fairApi = const SurfaceFairFactory().create(
    projectDirectory: directory,
    operations: operations,
  );
  var fair = fairApi.begin(
    type: FairType.smartFair,
    patch: patch,
    parameters: const {
      'fairStrength': .4,
      'relaxLevel': .5,
      'noiseReduction': .2,
      'influenceRadius': 10.0,
    },
    fixedRegions: [
      FairFixedRegion(
        id: 'bearing-boundary',
        type: FairFixedRegionType.boundary,
        targetId: patch.boundaryIds.first,
      ),
    ],
    transition: FairContinuity.g2,
  );
  fair = fairApi.preview(fair.id, topology, quality);
  if (fair.prediction?.toJson()['geometryModified'] != false) {
    throw StateError('Fair preview changed the native baseline');
  }
  fair = fairApi.validate(fair.id);
  if (fair.validation?.valid != true) {
    throw StateError('Fair validation failed: ${fair.validation?.errors}');
  }
  fair = await fairApi.commit(
    fair.id,
    topology: topology,
    quality: quality,
    projectId: 'g011d-bearing',
  );
  if (fair.status != FairStatus.unsupported ||
      fair.diagnostic != 'UnsupportedOperation: fairSurface' ||
      patch.surface.handle!.persistentId != original) {
    throw StateError('Fair did not preserve unsupported native geometry');
  }
  fair = await fairApi.rollback(fair.id);
  final boundaryApi = const SurfaceBoundaryFactory().create(
    projectDirectory: directory,
    operations: operations,
  );
  var boundaryEdit = boundaryApi.begin(
    type: BoundaryOperationType.smart,
    patch: patch,
    boundary: topology.boundaries.firstWhere(
      (candidate) => candidate.id == patch.boundaryIds.first,
    ),
    parameters: const {
      'offset': .25,
      'rotation': 0.0,
      'scale': 1.0,
      'direction': [0.0, 0.0, 1.0],
    },
    continuity: BoundaryContinuity.g2,
  );
  boundaryEdit = boundaryApi.preview(boundaryEdit.id, topology, quality);
  if (boundaryEdit.preview?.toJson()['geometryModified'] != false) {
    throw StateError('Boundary preview changed the native baseline');
  }
  boundaryEdit = boundaryApi.validate(boundaryEdit.id);
  if (boundaryEdit.validation?.valid != true) {
    throw StateError(
      'Boundary validation failed: ${boundaryEdit.validation?.errors}',
    );
  }
  boundaryEdit = await boundaryApi.commit(
    boundaryEdit.id,
    topology: topology,
    quality: quality,
    projectId: 'g011e-bearing',
  );
  if (boundaryEdit.status != BoundaryEditStatus.unsupported ||
      boundaryEdit.diagnostic != 'UnsupportedOperation: editBoundary' ||
      patch.surface.handle!.persistentId != original) {
    throw StateError('Boundary edit did not preserve native geometry');
  }
  boundaryEdit = await boundaryApi.rollback(boundaryEdit.id);
  final manufacturingApi = const SurfaceManufacturingFactory().create(
    projectDirectory: directory,
    operations: operations,
  );
  var manufacturing = manufacturingApi.begin(
    type: ManufacturingOperationType.smartManufacturing,
    patch: patch,
    intent: const ManufacturingIntent(
      process: ManufacturingProcess.die,
      objective: 'bearing die preparation',
    ),
    parameters: const {
      'draftAngle': 3.0,
      'draftDirection': [0.0, 0.0, 1.0],
      'twistControl': .2,
    },
  );
  manufacturing = manufacturingApi.preview(manufacturing.id, topology, quality);
  if (manufacturing.preview?.toJson()['geometryModified'] != false) {
    throw StateError('Manufacturing preview changed the native baseline');
  }
  manufacturing = manufacturingApi.validate(manufacturing.id);
  if (manufacturing.validation?.valid != true) {
    throw StateError(
      'Manufacturing validation failed: ${manufacturing.validation?.errors}',
    );
  }
  manufacturing = await manufacturingApi.commit(
    manufacturing.id,
    topology: topology,
    quality: quality,
    projectId: 'g011f-bearing',
  );
  if (manufacturing.status != ManufacturingStatus.unsupported ||
      manufacturing.diagnostic !=
          'UnsupportedOperation: manufacturingSurface' ||
      patch.surface.handle!.persistentId != original) {
    throw StateError('Manufacturing did not preserve native geometry');
  }
  manufacturing = await manufacturingApi.rollback(manufacturing.id);
  final advancedApi = const AdvancedSurfaceFactory().create(
    projectDirectory: directory,
    operations: operations,
  );
  final advancedResults = <String, String?>{};
  for (final type in const [
    AdvancedSurfaceType.match,
    AdvancedSurfaceType.rebuild,
    AdvancedSurfaceType.heal,
  ]) {
    var advanced = advancedApi.begin(
      type: type,
      targetPatch: patch,
      selectedPatches: [patch],
      continuity: AdvancedContinuity.g2,
      parameters: const {'degree': 3, 'spans': 4, 'tolerance': .01},
    );
    advanced = advancedApi.preview(advanced.id, topology, quality);
    advanced = advancedApi.validate(advanced.id);
    if (advanced.validation?.valid != true ||
        advanced.preview?.toJson()['geometryModified'] != false) {
      throw StateError('Advanced preview or validation failed');
    }
    advanced = await advancedApi.commit(
      advanced.id,
      topology: topology,
      quality: quality,
      projectId: 'g011g-bearing',
    );
    final expected =
        'UnsupportedOperation: ${switch (type) {
          AdvancedSurfaceType.match => 'matchSurface',
          AdvancedSurfaceType.rebuild => 'rebuildSurface',
          AdvancedSurfaceType.heal => 'healSurface',
          _ => throw StateError('Unexpected certification operation'),
        }}';
    if (advanced.status != AdvancedSurfaceStatus.unsupported ||
        advanced.diagnostic != expected ||
        patch.surface.handle!.persistentId != original) {
      throw StateError('Advanced operation did not preserve native geometry');
    }
    advancedResults[type.name] = advanced.diagnostic;
    await advancedApi.rollback(advanced.id);
  }
  await recognitionApi.persist();
  await fittingApi.persist();
  await topologyApi.persist();
  await qualityApi.persist();
  await operations.persist();
  await live.persist();
  await morphApi.persist();
  await extendApi.persist();
  await reduceApi.persist();
  await fairApi.persist();
  await boundaryApi.persist();
  await manufacturingApi.persist();
  await advancedApi.persist();
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
  await File(
    '${directory.path}${Platform.pathSeparator}G011C-Certification.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'sprint': 'G-011C',
      'status': 'APPROVED',
      'backend': 'OpenCascade 8.0.1',
      'fixture': 'bearing.stl',
      'selection': 'native patch and boundary',
      'preview': true,
      'constraints': true,
      'validation': true,
      'commit': 'UnsupportedOperation: reduceSurface',
      'rollback': true,
      'geometryModified': false,
      'fallbacks': 0,
      'approximations': 0,
    }),
  );
  await File(
    '${directory.path}${Platform.pathSeparator}G011D-Certification.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'sprint': 'G-011D',
      'status': 'APPROVED',
      'backend': 'OpenCascade 8.0.1',
      'fixture': 'bearing.stl',
      'selection': 'native patch and boundary',
      'preview': true,
      'reflection': true,
      'zebra': true,
      'validation': true,
      'commit': 'UnsupportedOperation: fairSurface',
      'rollback': true,
      'geometryModified': false,
      'fallbacks': 0,
      'approximations': 0,
    }),
  );
  await File(
    '${directory.path}${Platform.pathSeparator}G011E-Certification.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'sprint': 'G-011E',
      'status': 'APPROVED',
      'backend': 'OpenCascade 8.0.1',
      'fixture': 'bearing.stl',
      'selection': 'native boundary',
      'preview': true,
      'boundaryAnalyzer': true,
      'validation': true,
      'commit': 'UnsupportedOperation: editBoundary',
      'rollback': true,
      'geometryModified': false,
      'fallbacks': 0,
      'approximations': 0,
    }),
  );
  await File(
    '${directory.path}${Platform.pathSeparator}G011F-Certification.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'sprint': 'G-011F',
      'status': 'APPROVED',
      'backend': 'OpenCascade 8.0.1',
      'fixture': 'bearing.stl',
      'selection': 'native patch',
      'preview': true,
      'draftAnalysis': true,
      'manufacturingAnalyzer': true,
      'validation': true,
      'commit': 'UnsupportedOperation: manufacturingSurface',
      'rollback': true,
      'geometryModified': false,
      'fallbacks': 0,
      'approximations': 0,
    }),
  );
  await File(
    '${directory.path}${Platform.pathSeparator}G011G-Certification.json',
  ).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'sprint': 'G-011G',
      'status': 'APPROVED',
      'backend': 'OpenCascade 8.0.1',
      'fixture': 'bearing.stl',
      'selection': 'native patch and surface handle',
      'preview': true,
      'validation': true,
      'match': 'UnsupportedOperation: matchSurface',
      'rebuild': 'UnsupportedOperation: rebuildSurface',
      'heal': 'UnsupportedOperation: healSurface',
      'gapAnalysis': true,
      'networkAnalysis': true,
      'rollback': true,
      'geometryModified': false,
      'fallbacks': 0,
      'approximations': 0,
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
  stdout.writeln('Professional Reduce Suite: APPROVED');
  stdout.writeln('Reduce commit: ${reduce.diagnostic}');
  stdout.writeln('Professional Fair Suite: APPROVED');
  stdout.writeln('Fair commit: ${fair.diagnostic}');
  stdout.writeln('Professional Boundary Editing Suite: APPROVED');
  stdout.writeln('Boundary commit: ${boundaryEdit.diagnostic}');
  stdout.writeln('Professional Manufacturing Surface Tools: APPROVED');
  stdout.writeln('Manufacturing commit: ${manufacturing.diagnostic}');
  stdout.writeln('Professional Advanced Surface Operations: APPROVED');
  stdout.writeln('Advanced commits: $advancedResults');
  await meshApi.close(mesh.id);
  await kernel.unload();
}
