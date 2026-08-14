import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/live_validation/analytics/validation_analytics.dart';
import 'package:flcad_mobile/core/live_validation/api/live_validation_api.dart';
import 'package:flcad_mobile/core/live_validation/commands/fel_validation_commands.dart';
import 'package:flcad_mobile/core/live_validation/history/validation_history.dart';
import 'package:flcad_mobile/core/live_validation/history/validation_timeline.dart';
import 'package:flcad_mobile/core/live_validation/integration/validation_factory.dart';
import 'package:flcad_mobile/core/live_validation/integration/validation_studio.dart';
import 'package:flcad_mobile/core/live_validation/models/validation_models.dart';
import 'package:flcad_mobile/core/live_validation/repository/validation_repository.dart';
import 'package:flcad_mobile/core/live_validation/runtime/live_validation_runtime.dart';
import 'package:flcad_mobile/core/live_validation/validation/live_validation_validation.dart';
import 'package:flutter_test/flutter_test.dart';

class _ValidationContractKernel implements GeometryKernelAPI {
  _ValidationContractKernel({this.supported = true, this.available = true});
  final bool supported, available;
  int validations = 0, creates = 0;
  @override
  KernelDescriptor get descriptor => KernelDescriptor(
    id: 'validation-contract',
    name: 'Validation contract kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({if (supported) KernelCapability.meshing}),
  );
  @override
  Future<KernelHealth> healthCheck() async => KernelHealth(
    available ? KernelHealthStatus.healthy : KernelHealthStatus.unavailable,
    available ? 'ready' : 'offline',
    DateTime.now(),
  );
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async {
    validations++;
    final regions = checks
        .where((e) => e.startsWith('region:'))
        .map((e) => e.substring(7))
        .toList();
    return [
      'metric:max=0.12',
      'metric:average=0.04',
      'metric:rms=0.05',
      'metric:stddev=0.02',
      'metric:within=92',
      'metric:outside=8',
      'metric:critical=1',
      'metric:confidence=0.96',
      'metric:stability=94',
      'metric:quality=93',
      for (final region in regions) 'sample:$region,0.04,0.96',
    ];
  }

  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) {
    creates++;
    throw StateError('Live Validation must never create geometry');
  }

  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
}

void main() {
  late Directory project;
  late ShapeHandle targetShape;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_validation_');
    targetShape = ShapeHandle.reference(
      persistentId: 'cad-target',
      kernelId: 'validation-contract',
      type: CADShapeType.solid,
    );
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  LiveValidationApi make(GeometryKernelAPI kernel) =>
      const LiveValidationFactory().create(
        projectDirectory: project,
        kernel: kernel,
      );
  LiveValidationSession session(
    LiveValidationApi api, {
    ValidationParameters? parameters,
  }) => api.builder.build(
    source: const ValidationSource(
      id: 'mesh',
      type: ValidationSourceType.meshCad,
    ),
    target: ValidationSource(
      id: 'cad',
      type: ValidationSourceType.meshCad,
      shape: targetShape,
    ),
    parameters: parameters,
  );

  test('all comparison source contracts are available', () {
    expect(ValidationSourceType.values, hasLength(7));
    expect(ValidationUpdateType.values.length, greaterThanOrEqualTo(13));
    final api = make(_ValidationContractKernel());
    for (final type in ValidationSourceType.values) {
      api.builder.build(
        source: ValidationSource(id: 'source-${type.name}', type: type),
        target: ValidationSource(
          id: 'target-${type.name}',
          type: type,
          shape: targetShape,
        ),
      );
    }
    expect(api.sessions, hasLength(7));
  });

  test(
    'start produces backend metrics and heat map without geometry',
    () async {
      final kernel = _ValidationContractKernel(),
          api = make(kernel),
          value = session(api),
          result = await api.start(value.id);
      expect(result.success, isTrue);
      expect(value.metrics?.rms, .05);
      expect(value.metrics?.overallQuality, 93);
      expect(api.heatMap(value.id).points, isNotEmpty);
      expect(kernel.validations, 1);
      expect(kernel.creates, 0);
    },
  );

  test('pause resume stop gate incremental work explicitly', () async {
    final kernel = _ValidationContractKernel(),
        api = make(kernel),
        value = session(api);
    await api.start(value.id);
    api.pause(value.id);
    final paused = await api.engine.regionUpdate(value.id, const {'region'});
    expect(paused.status, LiveValidationStatus.paused);
    expect(kernel.validations, 1);
    api.resume(value.id);
    expect(
      (await api.engine.regionUpdate(value.id, const {'region'})).success,
      isTrue,
    );
    api.stop(value.id);
    expect(
      (await api.engine.regionUpdate(value.id, const {'region'})).status,
      LiveValidationStatus.stopped,
    );
  });

  test(
    'unavailable unsupported and incomplete backends are explicit',
    () async {
      final unavailable = _ValidationContractKernel(available: false),
          unsupported = _ValidationContractKernel(supported: false),
          a = make(unavailable),
          b = make(unsupported);
      expect(
        (await a.start(session(a).id)).status,
        LiveValidationStatus.kernelUnavailable,
      );
      expect(
        (await b.start(session(b).id)).status,
        LiveValidationStatus.unsupportedOperation,
      );
      expect(unavailable.creates + unsupported.creates, 0);
    },
  );

  test('validation rejects missing shape same source and tolerance', () {
    final api = make(_ValidationContractKernel()),
        value = api.builder.build(
          source: const ValidationSource(
            id: 'same',
            type: ValidationSourceType.meshCad,
          ),
          target: const ValidationSource(
            id: 'same',
            type: ValidationSourceType.meshCad,
          ),
          parameters: ValidationParameters(tolerance: 0),
        );
    expect(
      api.validate(value.id).issues.map((e) => e.type),
      containsAll([
        LiveValidationIssueType.sameSourceAndTarget,
        LiveValidationIssueType.invalidTolerance,
        LiveValidationIssueType.missingShape,
      ]),
    );
  });

  test('1000 incremental updates heat maps and timeline entries', () async {
    final kernel = _ValidationContractKernel(),
        api = make(kernel),
        value = session(api);
    value.status = LiveValidationStatus.running;
    for (var i = 0; i < 1000; i++) {
      expect(
        (await api.engine.regionUpdate(value.id, {'region-$i'})).success,
        isTrue,
      );
    }
    expect(api.engine.analytics.incrementalUpdates, 1000);
    expect(api.engine.analytics.heatMaps, 1000);
    expect(api.engine.timeline.entries, hasLength(1000));
    expect(value.samples, hasLength(1000));
    expect(kernel.creates, 0);
  });

  test(
    '1000 feature datum alignment and advisor updates are incremental',
    () async {
      final api = make(_ValidationContractKernel()), value = session(api);
      value.status = LiveValidationStatus.running;
      for (var i = 0; i < 1000; i++) {
        await api.engine.featureUpdate(value.id, 'feature-$i', {
          'feature-region-$i',
        });
        await api.engine.referenceUpdate(value.id, 'datum-$i', {
          'datum-region-$i',
        });
        await api.engine.alignmentUpdate(value.id, 'alignment-$i', {
          'alignment-region-$i',
        });
        api.recommendations(value.id);
      }
      expect(api.engine.analytics.featureUpdates, 1000);
      expect(api.engine.analytics.datumUpdates, 1000);
      expect(api.engine.analytics.alignmentUpdates, 1000);
      expect(api.engine.analytics.advisorUpdates, 1000);
      expect(api.engine.graph.featureInfluence, hasLength(1000));
      expect(api.engine.graph.referenceInfluence, hasLength(1000));
      expect(api.engine.graph.alignmentInfluence, hasLength(1000));
    },
  );

  test('1000 snapshots and rollbacks preserve measured state', () async {
    final api = make(_ValidationContractKernel()), value = session(api);
    await api.start(value.id);
    final snapshots = <ValidationSnapshot>[];
    for (var i = 0; i < 1000; i++) {
      snapshots.add(api.snapshot(value.id));
    }
    api.engine.createBaseline(value.id, snapshots.first.id);
    for (final snapshot in snapshots) {
      api.engine.rollback(value.id, snapshot.id);
    }
    expect(api.engine.analytics.snapshots, 1000);
    expect(api.engine.analytics.rollbacks, 1000);
    expect(
      api.engine.compareSnapshots(
        snapshots.first.id,
        snapshots.last.id,
      )['quality'],
      0,
    );
    api.engine.restoreBaseline(value.id);
  });

  test('repository dashboard FEL and passive bootstrap integrate', () async {
    final api = make(_ValidationContractKernel()), value = session(api);
    await api.start(value.id);
    await api.engine.persist();
    for (final path in ValidationRepository.paths) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(ValidationStudioAdapter.workspace, 'Validation Workspace');
    expect(ValidationStudioAdapter.panels, hasLength(7));
    expect(
      ValidationStudioAdapter()
          .buildTree(api.engine, 'project')
          .last
          .context['liveValidation'],
      isTrue,
    );
    expect(
      createLiveValidationFelCommands(api).length,
      greaterThanOrEqualTo(80),
    );
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services.get<LiveValidationRuntime>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<ValidationHistory>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<ValidationTimeline>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<ValidationAnalytics>(),
      isNotNull,
    );
  });
}
