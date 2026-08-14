import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/alignment_engine/analytics/alignment_analytics.dart';
import 'package:flcad_mobile/core/alignment_engine/api/alignment_api.dart';
import 'package:flcad_mobile/core/alignment_engine/commands/fel_alignment_commands.dart';
import 'package:flcad_mobile/core/alignment_engine/history/alignment_history.dart';
import 'package:flcad_mobile/core/alignment_engine/integration/alignment_factory.dart';
import 'package:flcad_mobile/core/alignment_engine/integration/alignment_studio.dart';
import 'package:flcad_mobile/core/alignment_engine/models/alignment_models.dart';
import 'package:flcad_mobile/core/alignment_engine/repository/alignment_repository.dart';
import 'package:flcad_mobile/core/alignment_engine/runtime/alignment_runtime.dart';
import 'package:flcad_mobile/core/alignment_engine/validation/alignment_validation.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _AlignmentContractKernel implements GeometryKernelAPI {
  _AlignmentContractKernel({this.supported = true, this.available = true});
  final bool supported, available;
  int creates = 0, begins = 0, commits = 0, rollbacks = 0;
  @override
  KernelDescriptor get descriptor => KernelDescriptor(
    id: 'alignment-contract',
    name: 'Alignment contract kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({if (supported) KernelCapability.brep}),
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
    expect(operation, 'ALIGNMENT_TRANSFORM');
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: descriptor.id,
      type: expectedType,
      fingerprint: 'kernel-owned-transform',
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
  late ShapeHandle moving, fixed;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_alignment_');
    moving = ShapeHandle.reference(
      persistentId: 'moving',
      kernelId: 'alignment-contract',
      type: CADShapeType.solid,
    );
    fixed = ShapeHandle.reference(
      persistentId: 'fixed',
      kernelId: 'alignment-contract',
      type: CADShapeType.solid,
    );
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  AlignmentApi make(GeometryKernelAPI kernel) => const AlignmentFactory()
      .create(projectDirectory: project, projectId: 'project', kernel: kernel);
  Alignment create(AlignmentApi api, AlignmentType type, {int index = 0}) =>
      api.builder.build(
        type: type,
        input: AlignmentInput(
          movingReferences: [
            AlignmentReference(
              id: 'moving-$index',
              source: AlignmentReferenceSource.persistentId,
            ),
          ],
          fixedReferences: [
            AlignmentReference(
              id: 'fixed-$index',
              source: AlignmentReferenceSource.persistentId,
            ),
          ],
          movingShape: moving,
          fixedShape: fixed,
        ),
      );

  test('all sixteen alignment contracts remain parametric', () {
    expect(AlignmentType.values, hasLength(16));
    expect(AlignmentReferenceSource.values, hasLength(12));
    final api = make(_AlignmentContractKernel());
    for (final type in AlignmentType.values) {
      expect(create(api, type).output, isNull);
    }
    expect(api.alignments, hasLength(16));
  });

  test('preview exposes full transform diagnostics without moving model', () {
    final kernel = _AlignmentContractKernel(),
        api = make(kernel),
        alignment = create(api, AlignmentType.plane),
        preview = api.preview(alignment.id);
    expect(preview.matrix.values, hasLength(16));
    expect(preview.rmsError, greaterThan(0));
    expect(preview.maximumError, greaterThan(preview.averageError));
    expect(preview.degreesOfFreedom, 6);
    expect(alignment.output, isNull);
    expect(kernel.creates, 0);
  });

  test('apply is provisional and commit exclusively invokes kernel', () async {
    final kernel = _AlignmentContractKernel(),
        api = make(kernel),
        alignment = create(api, AlignmentType.axis);
    api.apply(alignment.id);
    expect(alignment.status, AlignmentStatus.applied);
    expect(alignment.output, isNull);
    expect(kernel.creates, 0);
    final result = await api.commit(alignment.id);
    expect(result.success, isTrue);
    expect(result.shape?.fingerprint, 'kernel-owned-transform');
    expect(
      [kernel.creates, kernel.begins, kernel.commits, kernel.rollbacks],
      [1, 1, 1, 0],
    );
  });

  test('unavailable and unsupported kernels never create a result', () async {
    final offline = _AlignmentContractKernel(available: false),
        unsupported = _AlignmentContractKernel(supported: false),
        a = make(offline),
        b = make(unsupported);
    expect(
      (await a.commit(create(a, AlignmentType.plane).id)).status,
      AlignmentStatus.kernelUnavailable,
    );
    expect(
      (await b.commit(create(b, AlignmentType.axis).id)).status,
      AlignmentStatus.unsupportedOperation,
    );
    expect(offline.creates + unsupported.creates, 0);
  });

  test(
    'validation detects missing coincident mismatched and singular inputs',
    () {
      final api = make(_AlignmentContractKernel()),
          missing = api.builder.build(
            type: AlignmentType.manual,
            input: AlignmentInput(
              movingReferences: const [],
              fixedReferences: const [],
            ),
          ),
          coincident = api.builder.build(
            type: AlignmentType.plane,
            input: AlignmentInput(
              movingReferences: const [
                AlignmentReference(
                  id: 'same',
                  source: AlignmentReferenceSource.datumPlane,
                ),
              ],
              fixedReferences: const [
                AlignmentReference(
                  id: 'same',
                  source: AlignmentReferenceSource.datumPlane,
                ),
              ],
              movingShape: moving,
            ),
          ),
          singular = api.builder.build(
            type: AlignmentType.point,
            input: AlignmentInput(
              movingReferences: const [
                AlignmentReference(
                  id: 'a',
                  source: AlignmentReferenceSource.datumPoint,
                ),
              ],
              fixedReferences: const [
                AlignmentReference(
                  id: 'b',
                  source: AlignmentReferenceSource.datumPoint,
                ),
              ],
              movingShape: moving,
            ),
            parameters: AlignmentParameters(
              matrix: const AlignmentMatrix([
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
              ]),
            ),
          );
      expect(
        api.validate(missing.id).issues.map((e) => e.type),
        containsAll([
          AlignmentIssueType.missingReferences,
          AlignmentIssueType.missingShape,
        ]),
      );
      expect(
        api.validate(coincident.id).issues.map((e) => e.type),
        contains(AlignmentIssueType.coincidentReferences),
      );
      expect(
        api.validate(singular.id).issues.map((e) => e.type),
        contains(AlignmentIssueType.singularMatrix),
      );
    },
  );

  test('lock cancel replay undo and redo preserve explicit workflow', () {
    final api = make(_AlignmentContractKernel()),
        alignment = create(api, AlignmentType.manual);
    api.engine.lockAxis(alignment.id, 'X');
    api.apply(alignment.id);
    api.engine.replay(alignment.id);
    expect(alignment.parameters.lockedAxes, contains('X'));
    api.engine.unlockAxis(alignment.id, 'X');
    api.cancel(alignment.id);
    expect(alignment.status, AlignmentStatus.cancelled);
    expect(alignment.output, isNull);
    expect(api.engine.undo(), isTrue);
    expect(api.engine.redo(), isTrue);
  });

  test('1000 plane axis point coordinate best-fit and ICP alignments', () {
    final api = make(_AlignmentContractKernel());
    for (var i = 0; i < 1000; i++) {
      create(api, AlignmentType.plane, index: i);
      create(api, AlignmentType.axis, index: i);
      create(api, AlignmentType.point, index: i);
      create(api, AlignmentType.coordinateSystem, index: i);
      create(api, AlignmentType.bestFit, index: i);
      create(api, AlignmentType.icp, index: i);
    }
    expect(api.alignments, hasLength(6000));
    expect(api.alignments.map((e) => e.id).toSet(), hasLength(6000));
    expect(api.engine.analytics.bestFits, 1000);
    expect(api.engine.analytics.icp, 1000);
  });

  test('1000 rollback preview and dependency updates remain stable', () {
    final api = make(_AlignmentContractKernel()),
        parent = create(api, AlignmentType.plane),
        target = create(api, AlignmentType.axis);
    for (var i = 0; i < 1000; i++) {
      api.preview(target.id);
      api.rollback(target.id);
      api.engine.addDependency(target.id, parent.id);
    }
    expect(api.engine.analytics.previewUpdates, 1000);
    expect(api.engine.analytics.rollbacks, 1000);
    expect(api.engine.analytics.dependencyUpdates, 1000);
    expect(api.engine.graph.downstream(parent.id), contains(target.id));
  });

  test(
    'persistence advisor quality Studio FEL and bootstrap integrate',
    () async {
      final api = make(_AlignmentContractKernel()),
          alignment = create(api, AlignmentType.bestFit);
      api.preview(alignment.id);
      await api.engine.persist();
      for (final path in AlignmentRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(api.quality(alignment.id).overall, inInclusiveRange(0, 100));
      expect(
        api.recommendations(alignment.id).single.confidence,
        greaterThan(0),
      );
      expect(AlignmentStudioAdapter.workspace, 'Alignment Workspace');
      expect(AlignmentStudioAdapter.panels, hasLength(6));
      expect(createAlignmentFelCommands(api).length, greaterThanOrEqualTo(70));
      EngineeringBootstrap.instance.initialize();
      expect(
        EngineeringBootstrap.instance.services.get<AlignmentRuntime>(),
        isNotNull,
      );
      expect(
        EngineeringBootstrap.instance.services.get<AlignmentHistory>(),
        isNotNull,
      );
      expect(
        EngineeringBootstrap.instance.services.get<AlignmentAnalytics>(),
        isNotNull,
      );
    },
  );
}
