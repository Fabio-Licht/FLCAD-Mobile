import 'dart:io';

import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/feature_modeling/api/feature_modeling_api.dart';
import 'package:flcad_mobile/core/feature_modeling/integration/feature_modeling_factory.dart';
import 'package:flcad_mobile/core/profile_recognition/api/profile_recognition_api.dart';
import 'package:flcad_mobile/core/profile_recognition/integration/profile_factory.dart';
import 'package:flcad_mobile/core/profile_recognition/models/profile_models.dart';
import 'package:flcad_mobile/core/revolve_feature/analytics/revolve_analytics.dart';
import 'package:flcad_mobile/core/revolve_feature/api/revolve_api.dart';
import 'package:flcad_mobile/core/revolve_feature/commands/fel_revolve_commands.dart';
import 'package:flcad_mobile/core/revolve_feature/history/revolve_history.dart';
import 'package:flcad_mobile/core/revolve_feature/integration/revolve_factory.dart';
import 'package:flcad_mobile/core/revolve_feature/integration/revolve_studio.dart';
import 'package:flcad_mobile/core/revolve_feature/models/revolve_models.dart';
import 'package:flcad_mobile/core/revolve_feature/repository/revolve_repository.dart';
import 'package:flcad_mobile/core/revolve_feature/runtime/revolve_runtime.dart';
import 'package:flcad_mobile/core/revolve_feature/validation/revolve_validation.dart';
import 'package:flcad_mobile/core/sketch_engine/api/sketch_engine_api.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _RevolveKernel implements GeometryKernelAPI {
  _RevolveKernel({this.supported = true, this.available = true});
  final bool supported, available;
  int creates = 0, begins = 0, commits = 0, rollbacks = 0;
  @override
  KernelDescriptor get descriptor => KernelDescriptor(
    id: 'test-revolve',
    name: 'Test Revolve Kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({if (supported) KernelCapability.revolve}),
  );
  @override
  Future<KernelHealth> healthCheck() async => KernelHealth(
    available ? KernelHealthStatus.healthy : KernelHealthStatus.unavailable,
    available ? 'ready' : 'offline',
    DateTime.now(),
  );
  @override
  Future<void> begin(KernelTransaction transaction) async => begins++;
  @override
  Future<void> commit(KernelTransaction transaction) async => commits++;
  @override
  Future<void> rollback(KernelTransaction transaction) async => rollbacks++;
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async {
    creates++;
    expect(operation, 'REVOLVE');
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
  late ProfileRecognitionApi profiles;
  late FeatureModelingApi platform;
  late ShapeHandle profileShape;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_revolve_');
    final SketchEngineApi sketch = const SketchEngineFactory().create(project)
      ..createSketch('Revolve Sketch');
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
      kernelId: 'test-revolve',
      type: CADShapeType.face,
    );
  });

  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  RevolveApi make(GeometryKernelAPI kernel) => const RevolveFactory().create(
    projectDirectory: project,
    projectId: 'project',
    kernel: kernel,
    profiles: profiles,
    featurePlatform: platform,
  );

  RevolveFeature prepare(RevolveApi api, {double angle = 360}) =>
      api.builder.build(
        input: RevolveInput(
          sketchId: 'sketch',
          profileIds: const ['profile-1'],
          axis: RevolveAxis(
            origin: const SketchVector(0, 0),
            direction: const SketchVector(0, 1),
          ),
          kernelProfile: profileShape,
        ),
        parameters: RevolveParameters(angle: angle),
      );

  test('all 14 revolve variants remain parametric until confirmation', () {
    expect(RevolveType.values, hasLength(14));
    final api = make(_RevolveKernel());
    for (final type in RevolveType.values) {
      final feature = prepare(api)..parameters.type = type;
      expect(feature.output, isNull);
    }
    expect(api.revolves, hasLength(14));
  });

  test('preview exposes metadata and never creates geometry', () {
    final kernel = _RevolveKernel(), api = make(kernel), feature = prepare(api);
    final preview = api.preview(feature.id);
    expect(preview.predictedVolume, greaterThan(0));
    expect(preview.predictedFaces, 4);
    expect(preview.readiness, isTrue);
    expect(feature.output, isNull);
    expect(kernel.creates, 0);
  });

  test('official kernel is the exclusive geometry execution path', () async {
    final kernel = _RevolveKernel(), api = make(kernel), feature = prepare(api);
    final result = await api.confirm(feature.id);
    expect(result.success, isTrue);
    expect(result.shape?.fingerprint, 'real-kernel-result');
    expect(result.shape?.type, CADShapeType.solid);
    expect(
      [kernel.creates, kernel.begins, kernel.commits, kernel.rollbacks],
      [1, 1, 1, 0],
    );
    expect(
      platform.engine.features[feature.id]!.result!.outputs.single.handle,
      result.shape,
    );
  });

  test('unavailable and unsupported kernels create no geometry', () async {
    final offline = _RevolveKernel(available: false);
    final unsupported = _RevolveKernel(supported: false);
    final a = make(offline), b = make(unsupported);
    final ra = await a.confirm(prepare(a).id);
    final rb = await b.confirm(prepare(b).id);
    expect(ra.status, RevolveStatus.kernelUnavailable);
    expect(rb.status, RevolveStatus.unsupportedOperation);
    expect(offline.creates + unsupported.creates, 0);
  });

  test('validation detects profile, axis, angle and reference defects', () {
    profiles.engine.profiles['open'] = RecognizedProfile(
      id: 'open',
      type: ProfileType.open,
      entityIds: const [],
      area: 0,
    );
    final api = make(_RevolveKernel());
    final feature = api.builder.build(
      input: RevolveInput(
        sketchId: 's',
        profileIds: const ['open'],
        axis: RevolveAxis(
          origin: const SketchVector(0, 0),
          direction: const SketchVector(0, 0),
        ),
      ),
      parameters: RevolveParameters(angle: 0),
    );
    expect(
      api.validate(feature.id).issues.map((issue) => issue.type),
      containsAll([
        RevolveValidationIssueType.openProfile,
        RevolveValidationIssueType.invalidAxis,
        RevolveValidationIssueType.zeroAngle,
        RevolveValidationIssueType.missingReference,
      ]),
    );
  });

  test('1000 revolves preserve previews, rollback, edits and dependencies', () {
    final api = make(_RevolveKernel());
    final values = [
      for (var i = 0; i < 1000; i++)
        prepare(api, angle: (i % 360 + 1).toDouble()),
    ];
    for (final value in values) {
      api.preview(value.id);
    }
    final target = values.last, parent = values.first;
    for (var i = 0; i < 1000; i++) {
      api.rollback(target.id);
      api.engine.updateParameters(
        target.id,
        (p) => p.angle = (i % 360 + 1).toDouble(),
      );
      api.engine.updateAxis(target.id, (a) => a.reverse = !a.reverse);
      api.engine.addDependency(target.id, parent.id);
    }
    expect(api.revolves, hasLength(1000));
    expect(api.engine.previews, hasLength(1000));
    expect(api.engine.analytics.rollbacks, 1000);
    expect(api.engine.analytics.parameterUpdates, 1000);
    expect(api.engine.analytics.axisUpdates, 1000);
    expect(api.engine.graph.downstream(parent.id), contains(target.id));
  });

  test('1000 rebuilds remain transactional and traceable', () async {
    final kernel = _RevolveKernel(), api = make(kernel), feature = prepare(api);
    for (var i = 0; i < 1000; i++) {
      expect((await api.rebuild(feature.id)).success, isTrue);
    }
    expect(kernel.creates, 1000);
    expect(api.engine.analytics.rebuilds, 1000);
    expect(api.engine.analytics.successRate, 1);
  });

  test(
    'persistence, UI, FEL and passive bootstrap contracts are present',
    () async {
      final api = make(_RevolveKernel()), feature = prepare(api);
      api.preview(feature.id);
      await api.engine.persist();
      for (final path in RevolveRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(RevolveStudioAdapter.panels, hasLength(8));
      expect(
        RevolveStudioAdapter()
            .buildTree(api.engine, 'project')
            .last
            .context['revolveFeature'],
        isTrue,
      );
      expect(createRevolveFelCommands(api), hasLength(40));
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services.get<RevolveRuntime>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<RevolveHistory>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<RevolveAnalytics>(),
      isNotNull,
    );
    },
  );
}
