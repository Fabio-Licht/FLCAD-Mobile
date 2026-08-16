import 'dart:io';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/parametric_engineering/analytics/engineering_quality.dart';
import 'package:flcad_mobile/core/parametric_engineering/api/parametric_api.dart';
import 'package:flcad_mobile/core/parametric_engineering/builders/feature_builder.dart';
import 'package:flcad_mobile/core/parametric_engineering/engine/parametric_engineering_engine.dart';
import 'package:flcad_mobile/core/parametric_engineering/features/engineering_feature.dart';
import 'package:flcad_mobile/core/parametric_engineering/features/feature_dna.dart';
import 'package:flcad_mobile/core/parametric_engineering/kernel/geometry_kernel_adapter.dart';
import 'package:flcad_mobile/core/parametric_engineering/serialization/parametric_repository.dart';
import 'package:flcad_mobile/core/parametric_engineering/timeline/engineering_timeline.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all feature kinds share EFD infrastructure', () {
    for (final kind in FeatureKind.values) {
      final f = const FeatureBuilder().build(
        FeatureRecipe(
          projectId: 'p',
          name: 'F',
          kind: kind,
          sourceIds: const ['source'],
        ),
      );
      expect(f.kind, kind);
      expect(f.dna.hash, isNotEmpty);
    }
  });
  test('EFD changes with engineering intent', () {
    final a = createFeatureDNA(
          origins: const ['s'],
          intent: 'support',
          parameters: const {},
          manufacturing: ManufacturingStrategy.machining,
          inspection: InspectionStrategy.cmm,
          relations: const [],
        ),
        b = createFeatureDNA(
          origins: const ['s'],
          intent: 'aesthetic',
          parameters: const {},
          manufacturing: ManufacturingStrategy.machining,
          inspection: InspectionStrategy.cmm,
          relations: const [],
        );
    expect(a.hash, isNot(b.hash));
  });
  test('timeline supports branch replay and merge', () {
    final t = EngineeringTimeline()
      ..branch(const TimelineBranch('alternative', 'Alternative', 'main', 0));
    t.append(
      EngineeringDecision(
        id: '1',
        projectId: 'p',
        branchId: 'main',
        entityId: 'f',
        action: 'create',
        reason: 'intent',
        timestamp: DateTime.utc(2026),
        sequence: 1,
      ),
    );
    t.append(
      EngineeringDecision(
        id: '2',
        projectId: 'p',
        branchId: 'alternative',
        entityId: 'f',
        action: 'change',
        reason: 'test',
        timestamp: DateTime.utc(2026, 1, 2),
        sequence: 2,
      ),
    );
    expect(t.replay('main'), hasLength(1));
    expect(t.merge('main', 'alternative'), hasLength(2));
  });
  test('unavailable kernel never fabricates B-Rep', () async {
    final f = const FeatureBuilder().build(
      const FeatureRecipe(
        projectId: 'p',
        name: 'E',
        kind: FeatureKind.extrude,
        sourceIds: ['s'],
        parameters: {'distance': 1},
      ),
    );
    expect(
      () => const UnavailableGeometryKernel().executeFeature(f, const []),
      throwsUnsupportedError,
    );
  });
  test('FEL exposes PED vocabulary', () {
    final r = createNativeCommandRegistry(Directory.systemTemp);
    for (final n in [
      'CREATE FEATURE',
      'CREATE SOLID',
      'EXTRUDE',
      'REVOLVE',
      'SWEEP',
      'LOFT',
      'BOOLEAN UNION',
      'BOOLEAN SUBTRACT',
      'BOOLEAN INTERSECT',
      'FILLET',
      'CHAMFER',
      'SHELL',
      'PATTERN',
      'MIRROR',
      'VALIDATE FEATURE',
      'VALIDATE SOLID',
    ]) {
      expect(r.find(n), isNotNull);
    }
  });
  test(
    'engine persists pending features, graph, DET and solid definitions',
    () async {
      final root = await Directory.systemTemp.createTemp('ped_');
      addTearDown(() => root.delete(recursive: true));
      final projects = ProjectRepository(
            storage: LocalStorageService(rootDirectory: root),
          ),
          project = await projects.create(name: 'P', client: 'C'),
          api = ParametricApi(
            engine: ParametricEngineeringEngine(
              repository: ParametricRepository(projects: projects),
            ),
          ),
          feature = await api.createFeature(
            FeatureRecipe(
              projectId: project.id,
              name: 'Extrude',
              kind: FeatureKind.extrude,
              sourceIds: const ['sketch'],
              parameters: const {'distance': 10},
              manufacturing: ManufacturingStrategy.machining,
              inspection: InspectionStrategy.cmm,
            ),
          );
      expect(feature.status, FeatureStatus.pendingKernel);
      expect(api.validateFeature(feature).valid, isTrue);
      final solid = await api.createSolid(project.id, 'Solid', [feature]);
      expect(solid.handle, isNull);
      expect(
        const EngineeringQualityEngine().evaluate([feature], [solid]).total,
        inInclusiveRange(0, 1),
      );
      final dir = await projects.directoryFor(project.id);
      for (final name in [
        'features.json',
        'feature_graph.json',
        'engineering_history.json',
        'timeline.json',
        'solid.json',
      ]) {
        expect(await File('${dir.path}/Features/$name').exists(), isTrue);
      }
    },
  );
}
