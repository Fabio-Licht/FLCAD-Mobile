import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/extrude_feature/analytics/extrude_analytics.dart';
import 'package:flcad_mobile/core/extrude_feature/api/extrude_api.dart';
import 'package:flcad_mobile/core/extrude_feature/commands/fel_extrude_commands.dart';
import 'package:flcad_mobile/core/extrude_feature/history/extrude_history.dart';
import 'package:flcad_mobile/core/extrude_feature/integration/extrude_factory.dart';
import 'package:flcad_mobile/core/extrude_feature/integration/extrude_studio.dart';
import 'package:flcad_mobile/core/extrude_feature/models/extrude_models.dart';
import 'package:flcad_mobile/core/extrude_feature/repository/extrude_repository.dart';
import 'package:flcad_mobile/core/extrude_feature/runtime/extrude_runtime.dart';
import 'package:flcad_mobile/core/extrude_feature/validation/extrude_validation.dart';
import 'package:flcad_mobile/core/feature_modeling/integration/feature_modeling_factory.dart';
import 'package:flcad_mobile/core/feature_modeling/api/feature_modeling_api.dart';
import 'package:flcad_mobile/core/profile_recognition/integration/profile_factory.dart';
import 'package:flcad_mobile/core/profile_recognition/api/profile_recognition_api.dart';
import 'package:flcad_mobile/core/profile_recognition/models/profile_models.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/api/sketch_engine_api.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExtrudeKernel implements GeometryKernelAPI {
  _ExtrudeKernel({this.supported = true, this.available = true});
  final bool supported, available;
  int creates = 0, begins = 0, commits = 0, rollbacks = 0;
  @override
  KernelDescriptor get descriptor => KernelDescriptor(
    id: 'test-extrude',
    name: 'Test Extrude Kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({if (supported) KernelCapability.extrude}),
  );
  @override
  Future<KernelHealth> healthCheck() async => KernelHealth(
    available ? KernelHealthStatus.healthy : KernelHealthStatus.unavailable,
    available ? 'ready' : 'offline',
    DateTime.now(),
  );
  @override
  Future<void> begin(KernelTransaction transaction) async {
    begins++;
  }

  @override
  Future<void> commit(KernelTransaction transaction) async {
    commits++;
  }

  @override
  Future<void> rollback(KernelTransaction transaction) async {
    rollbacks++;
  }

  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async {
    creates++;
    expect(operation, 'EXTRUDE');
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: descriptor.id,
      type: expectedType,
      fingerprint: 'real-kernel-result',
    );
  }

  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<void> unload() async {}
}

void main() {
  late Directory project;
  late SketchEngineApi sketch;
  late ProfileRecognitionApi profiles;
  late FeatureModelingApi platform;
  late ShapeHandle profileShape;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_extrude_');
    sketch = const SketchEngineFactory().create(project)
      ..createSketch('Extrude Sketch');
    profiles = const ProfileRecognitionFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
    profiles.engine.profiles['profile-1'] = RecognizedProfile(
      id: 'profile-1',
      type: ProfileType.closed,
      entityIds: const [],
      area: 20,
      perimeter: 18,
    );
    platform = const FeatureModelingFactory().create(
      projectDirectory: project,
      projectId: 'project',
    );
    profileShape = ShapeHandle.reference(
      persistentId: 'profile-shape',
      kernelId: 'test-extrude',
      type: CADShapeType.face,
    );
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  ExtrudeApi make(GeometryKernelAPI kernel) => const ExtrudeFactory().create(
    projectDirectory: project,
    projectId: 'project',
    kernel: kernel,
    profiles: profiles,
    featurePlatform: platform,
  );
  ExtrudeFeature prepare(
    ExtrudeApi api, {
    double distance = 10.0,
    ShapeHandle? shape,
  }) => api.builder.build(
    input: ExtrudeInput(
      sketchId: 'sketch',
      profileIds: const ['profile-1'],
      regionIds: const ['region-1'],
      kernelProfile: shape ?? profileShape,
    ),
    parameters: ExtrudeParameters(distance: distance),
  );

  test('all professional extrude contracts remain parametric', () {
    expect(ExtrudeType.values, hasLength(16));
    final api = make(_ExtrudeKernel());
    for (final type in ExtrudeType.values) {
      final e = api.builder.build(
        input: ExtrudeInput(
          sketchId: 's',
          profileIds: const ['profile-1'],
          kernelProfile: profileShape,
        ),
        parameters: ExtrudeParameters(type: type, distance: 2),
      );
      expect(e.output, isNull);
    }
    expect(api.extrudes, hasLength(16));
  });
  test('preview predicts information but creates no shape', () {
    final kernel = _ExtrudeKernel(), api = make(kernel), e = prepare(api);
    final preview = api.preview(e.id);
    expect(preview.predictedVolume, 200);
    expect(preview.boundingBox.depth, 10);
    expect(preview.predictedFaces, 6);
    expect(preview.readiness, isTrue);
    expect(e.output, isNull);
    expect(kernel.creates, 0);
  });
  test('supported kernel is the exclusive geometry execution path', () async {
    final kernel = _ExtrudeKernel(), api = make(kernel), e = prepare(api);
    final result = await api.confirm(e.id);
    expect(result.success, isTrue);
    expect(result.shape, isNotNull);
    expect(result.shape!.fingerprint, 'real-kernel-result');
    expect(result.shape!.type, CADShapeType.solid);
    expect(kernel.creates, 1);
    expect(kernel.begins, 1);
    expect(kernel.commits, 1);
    expect(kernel.rollbacks, 0);
    expect(
      platform.engine.features[e.id]!.result!.outputs.single.handle,
      result.shape,
    );
  });
  test(
    'kernel unavailable and unsupported capability create no shape',
    () async {
      final offline = _ExtrudeKernel(available: false),
          unsupported = _ExtrudeKernel(supported: false);
      final a = make(offline),
          b = make(unsupported),
          ea = prepare(a),
          eb = prepare(b);
      final ra = await a.confirm(ea.id), rb = await b.confirm(eb.id);
      expect(ra.status, ExtrudeStatus.kernelUnavailable);
      expect(rb.status, ExtrudeStatus.unsupportedOperation);
      expect(ra.shape, isNull);
      expect(rb.shape, isNull);
      expect(offline.creates + unsupported.creates, 0);
    },
  );
  test(
    'validation catches profile direction distance and official shape errors',
    () {
      profiles.engine.profiles['open'] = RecognizedProfile(
        id: 'open',
        type: ProfileType.open,
        entityIds: const [],
        area: 0,
      );
      final api = make(_ExtrudeKernel()),
          e = api.builder.build(
            input: ExtrudeInput(sketchId: 's', profileIds: const ['open']),
            parameters: ExtrudeParameters(
              distance: 0,
              direction: const SketchVector(0, 0, 0),
            ),
          );
      final issues = api.validate(e.id).issues.map((i) => i.type);
      expect(
        issues,
        containsAll([
          ExtrudeValidationIssueType.openProfile,
          ExtrudeValidationIssueType.zeroArea,
          ExtrudeValidationIssueType.missingDirection,
          ExtrudeValidationIssueType.missingDistance,
          ExtrudeValidationIssueType.invalidReference,
        ]),
      );
    },
  );
  test('1000 extrudes previews rollbacks parameter and dependency updates', () {
    final api = make(_ExtrudeKernel()), values = <ExtrudeFeature>[];
    for (var i = 0; i < 1000; i++) {
      values.add(prepare(api, distance: (i + 1).toDouble()));
    }
    expect(api.extrudes, hasLength(1000));
    for (final e in values) {
      api.preview(e.id);
    }
    expect(api.engine.previews, hasLength(1000));
    final target = values.last, parent = values.first;
    for (var i = 0; i < 1000; i++) {
      api.engine.rollback(target.id);
      api.engine.updateParameters(
        target.id,
        (p) => p.distance = (i + 1).toDouble(),
      );
      api.engine.addDependency(target.id, parent.id);
    }
    expect(api.engine.analytics.rollback, 1000);
    expect(api.engine.analytics.parameterUpdates, 1000);
    expect(api.engine.analytics.dependencyUpdates, 1000);
    expect(api.engine.graph.downstream(parent.id), contains(target.id));
  });
  test('1000 rebuilds use kernel and remain traceable', () async {
    final kernel = _ExtrudeKernel(), api = make(kernel), e = prepare(api);
    for (var i = 0; i < 1000; i++) {
      expect((await api.rebuild(e.id)).success, isTrue);
    }
    expect(kernel.creates, 1000);
    expect(api.engine.analytics.rebuilds, 1000);
    expect(api.engine.analytics.successRate, 1);
  });
  test(
    'undo redo suppression advisor quality repository Studio FEL and bootstrap integrate',
    () async {
      final api = make(_ExtrudeKernel()), e = prepare(api);
      expect(api.engine.undo(), isTrue);
      expect(api.extrudes, isEmpty);
      expect(api.engine.redo(), isTrue);
      api.engine.suppress(e.id, true);
      expect(api.engine.extrudes[e.id]!.status, ExtrudeStatus.suppressed);
      api.engine.suppress(e.id, false);
      expect(api.recommendations(e.id), isA<List>());
      expect(api.quality(e.id).overall, inInclusiveRange(0, 100));
      await api.engine.persist();
      for (final path in ExtrudeRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(
        createExtrudeFelCommands(api).map((c) => c.name).toSet(),
        hasLength(40),
      );
      expect(api.engine.runtime.isInitialized, isFalse);
      final node = const ExtrudeStudioAdapter()
          .buildTree(api.engine, 'project')
          .firstWhere((n) => n.id == e.id);
      final section = const PropertyInspector()
          .inspect(node)
          .firstWhere((s) => s.name == 'Extrude Feature');
      expect(
        section.values.keys,
        containsAll([
          'extrudeType',
          'distance',
          'direction',
          'profile',
          'target',
          'merge',
          'draft',
          'persistentId',
          'history',
          'dependencies',
          'kernelStatus',
          'quality',
        ]),
      );
      final bootstrap = EngineeringBootstrap.instance..initialize();
      expect(bootstrap.services.get<ExtrudeFactory>(), isNotNull);
      expect(bootstrap.services.get<ExtrudeRuntime>(), isNotNull);
      expect(bootstrap.services.get<ExtrudeRepository>(), isNotNull);
      expect(bootstrap.services.get<ExtrudeAnalytics>(), isNotNull);
      expect(bootstrap.services.get<ExtrudeHistory>(), isNotNull);
    },
  );
}
