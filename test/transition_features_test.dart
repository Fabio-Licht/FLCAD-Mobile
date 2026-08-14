import 'dart:io';

import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/feature_modeling/api/feature_modeling_api.dart';
import 'package:flcad_mobile/core/feature_modeling/integration/feature_modeling_factory.dart';
import 'package:flcad_mobile/core/profile_recognition/api/profile_recognition_api.dart';
import 'package:flcad_mobile/core/profile_recognition/integration/profile_factory.dart';
import 'package:flcad_mobile/core/profile_recognition/models/profile_models.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/transition_features/analytics/transition_analytics.dart';
import 'package:flcad_mobile/core/transition_features/api/transition_api.dart';
import 'package:flcad_mobile/core/transition_features/commands/fel_transition_commands.dart';
import 'package:flcad_mobile/core/transition_features/history/transition_history.dart';
import 'package:flcad_mobile/core/transition_features/integration/transition_factory.dart';
import 'package:flcad_mobile/core/transition_features/integration/transition_studio.dart';
import 'package:flcad_mobile/core/transition_features/models/transition_models.dart';
import 'package:flcad_mobile/core/transition_features/repository/transition_repository.dart';
import 'package:flcad_mobile/core/transition_features/runtime/transition_runtime.dart';
import 'package:flcad_mobile/core/transition_features/validation/transition_validation.dart';
import 'package:flutter_test/flutter_test.dart';

class _ContractKernel implements GeometryKernelAPI {
  _ContractKernel({this.sweep = true, this.loft = true, this.available = true});
  final bool sweep, loft, available;
  int creates = 0, begins = 0, commits = 0, rollbacks = 0;
  @override
  KernelDescriptor get descriptor => KernelDescriptor(
    id: 'contract-kernel',
    name: 'Geometry contract kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({
      if (sweep) KernelCapability.sweep,
      if (loft) KernelCapability.loft,
    }),
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
    expect(operation, anyOf('SWEEP', 'LOFT'));
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: descriptor.id,
      type: expectedType,
      fingerprint: 'kernel-owned-result',
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
  late ShapeHandle profileA, profileB, path, guide;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_transition_');
    final sketch = const SketchEngineFactory().create(project)
      ..createSketch('Transition Sketch');
    profiles = const ProfileRecognitionFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
    for (final id in const ['profile-a', 'profile-b']) {
      profiles.engine.profiles[id] = RecognizedProfile(
        id: id,
        type: ProfileType.closed,
        entityIds: const [],
        area: 20,
        perimeter: 18,
      );
    }
    platform = const FeatureModelingFactory().create(
      projectDirectory: project,
      projectId: 'project',
    );
    profileA = ShapeHandle.reference(
      persistentId: 'profile-a-shape',
      kernelId: 'contract-kernel',
      type: CADShapeType.face,
    );
    profileB = ShapeHandle.reference(
      persistentId: 'profile-b-shape',
      kernelId: 'contract-kernel',
      type: CADShapeType.face,
    );
    path = ShapeHandle.reference(
      persistentId: 'path-shape',
      kernelId: 'contract-kernel',
      type: CADShapeType.edge,
    );
    guide = ShapeHandle.reference(
      persistentId: 'guide-shape',
      kernelId: 'contract-kernel',
      type: CADShapeType.edge,
    );
  });

  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  TransitionApi make(GeometryKernelAPI kernel) =>
      const TransitionFactory().create(
        projectDirectory: project,
        projectId: 'project',
        kernel: kernel,
        profiles: profiles,
        featurePlatform: platform,
      );

  TransitionFeature sweep(TransitionApi api, {int index = 0}) =>
      api.sweeps.build(
        input: TransitionInput(
          profileIds: const ['profile-a'],
          pathIds: ['path-$index'],
          guideIds: ['guide-$index'],
          kernelProfiles: [profileA],
          kernelPaths: [path],
          kernelGuides: [guide],
        ),
        parameters: TransitionParameters(sweepType: SweepType.boss),
      );

  TransitionFeature loft(TransitionApi api, {int index = 0}) => api.lofts.build(
    input: TransitionInput(
      profileIds: const ['profile-a', 'profile-b'],
      sectionIds: ['section-$index'],
      guideIds: ['guide-$index'],
      kernelProfiles: [profileA, profileB],
      kernelGuides: [guide],
    ),
    parameters: TransitionParameters(loftType: LoftType.solid),
  );

  test('all professional Sweep and Loft contracts are available', () {
    expect(SweepType.values, hasLength(8));
    expect(LoftType.values, hasLength(8));
    final api = make(_ContractKernel());
    for (final type in SweepType.values) {
      expect((sweep(api)..parameters.sweepType = type).output, isNull);
    }
    for (final type in LoftType.values) {
      expect((loft(api)..parameters.loftType = type).output, isNull);
    }
    expect(api.features, hasLength(16));
  });

  test('preview is independent and creates no geometry', () {
    final kernel = _ContractKernel(), api = make(kernel);
    final a = api.preview(sweep(api).id), b = api.preview(loft(api).id);
    expect(a.operation, 'SWEEP');
    expect(b.operation, 'LOFT');
    expect(a.complexityScore, greaterThan(0));
    expect(b.sections, 3);
    expect(a.readiness && b.readiness, isTrue);
    expect(kernel.creates, 0);
  });

  test('supported kernel exclusively executes both operations', () async {
    final kernel = _ContractKernel(), api = make(kernel);
    final a = await api.confirm(sweep(api).id),
        b = await api.confirm(loft(api).id);
    expect(a.success && b.success, isTrue);
    expect(a.shape?.fingerprint, 'kernel-owned-result');
    expect(b.shape?.fingerprint, 'kernel-owned-result');
    expect(
      [kernel.creates, kernel.begins, kernel.commits, kernel.rollbacks],
      [2, 2, 2, 0],
    );
  });

  test('unavailable and unsupported operations create no result', () async {
    final offline = _ContractKernel(available: false),
        unsupported = _ContractKernel(sweep: false, loft: false);
    final a = make(offline), b = make(unsupported);
    expect(
      (await a.confirm(sweep(a).id)).status,
      TransitionStatus.kernelUnavailable,
    );
    expect(
      (await b.confirm(loft(b).id)).status,
      TransitionStatus.unsupportedOperation,
    );
    expect(offline.creates + unsupported.creates, 0);
  });

  test('validation diagnoses missing inputs and official handles', () {
    final api = make(_ContractKernel());
    final a = api.sweeps.build(
      input: TransitionInput(profileIds: const []),
      parameters: TransitionParameters(sweepType: SweepType.boss),
    );
    final b = api.lofts.build(
      input: TransitionInput(profileIds: const ['profile-a']),
      parameters: TransitionParameters(loftType: LoftType.solid),
    );
    expect(
      api.validate(a.id).issues.map((e) => e.type),
      containsAll([
        TransitionIssueType.missingProfile,
        TransitionIssueType.missingPath,
        TransitionIssueType.missingShapeHandle,
        TransitionIssueType.zeroLengthPath,
      ]),
    );
    expect(
      api.validate(b.id).issues.map((e) => e.type),
      containsAll([
        TransitionIssueType.missingSection,
        TransitionIssueType.missingShapeHandle,
      ]),
    );
  });

  test('1000 Sweeps, Lofts, paths and guides remain parametric', () {
    final api = make(_ContractKernel()),
        sweeps = <TransitionFeature>[],
        lofts = <TransitionFeature>[];
    for (var i = 0; i < 1000; i++) {
      sweeps.add(sweep(api, index: i));
      lofts.add(loft(api, index: i));
    }
    expect(api.features, hasLength(2000));
    expect(api.engine.analytics.sweeps, 1000);
    expect(api.engine.analytics.lofts, 1000);
    expect(sweeps.map((e) => e.input.pathIds.single).toSet(), hasLength(1000));
    expect(lofts.map((e) => e.input.guideIds.single).toSet(), hasLength(1000));
    expect(api.features.every((e) => e.output == null), isTrue);
  });

  test(
    '1000 rebuilds, rollbacks, updates and dependencies are stable',
    () async {
      final kernel = _ContractKernel(),
          api = make(kernel),
          parent = sweep(api),
          target = loft(api);
      for (var i = 0; i < 1000; i++) {
        expect((await api.rebuild(target.id)).success, isTrue);
        api.rollback(target.id);
        api.engine.updateParameters(
          target.id,
          (p) => p.thickness = i.toDouble(),
        );
        api.engine.addDependency(target.id, parent.id);
      }
      expect(kernel.creates, 1000);
      expect(api.engine.analytics.rebuilds, 1000);
      expect(api.engine.analytics.rollbacks, 1000);
      expect(api.engine.analytics.parameterUpdates, 1000);
      expect(api.engine.analytics.dependencyUpdates, 1000);
      expect(api.engine.graph.downstream(parent.id), contains(target.id));
    },
  );

  test('undo redo persistence Studio FEL and bootstrap integrate', () async {
    final api = make(_ContractKernel()), feature = sweep(api);
    api.preview(feature.id);
    expect(api.engine.undo(), isTrue);
    expect(api.engine.redo(), isTrue);
    await api.engine.persist();
    for (final pathName in TransitionRepository.paths) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}${pathName.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(TransitionStudioAdapter.panels, hasLength(8));
    expect(createTransitionFelCommands(api).length, greaterThanOrEqualTo(50));
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services.get<TransitionRuntime>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<TransitionHistory>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<TransitionAnalytics>(),
      isNotNull,
    );
  });
}
