import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/engineering_intelligence/analytics/intelligence_analytics.dart';
import 'package:flcad_mobile/core/engineering_intelligence/api/engineering_intelligence_api.dart';
import 'package:flcad_mobile/core/engineering_intelligence/commands/fel_intelligence_commands.dart';
import 'package:flcad_mobile/core/engineering_intelligence/history/intelligence_history.dart';
import 'package:flcad_mobile/core/engineering_intelligence/integration/intelligence_factory.dart';
import 'package:flcad_mobile/core/engineering_intelligence/integration/intelligence_studio.dart';
import 'package:flcad_mobile/core/engineering_intelligence/models/intelligence_models.dart';
import 'package:flcad_mobile/core/engineering_intelligence/repository/intelligence_repository.dart';
import 'package:flcad_mobile/core/engineering_intelligence/runtime/intelligence_runtime.dart';
import 'package:flcad_mobile/core/engineering_intelligence/validation/intelligence_validation.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReadOnlyKernel implements GeometryKernelAPI {
  int creates = 0;
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'readonly',
    name: 'Read-only kernel evidence',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities.none,
  );
  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ready', DateTime.now());
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) {
    creates++;
    throw StateError('Engineering Intelligence must never create geometry');
  }

  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) =>
      throw StateError(
        'Engineering Intelligence must not execute geometry validation',
      );
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
  late _ReadOnlyKernel kernel;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_intelligence_');
    kernel = _ReadOnlyKernel();
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  EngineeringIntelligenceApi make() => const EngineeringIntelligenceFactory()
      .create(projectDirectory: project, kernel: kernel);
  ProjectKnowledgeSnapshot snapshot({int index = 0}) =>
      ProjectKnowledgeSnapshot(
        projectId: 'project-$index',
        features: 12,
        references: 5,
        alignments: 2,
        validations: 3,
        sketches: 4,
        constraints: 20,
        profiles: 4,
        averageFeatureQuality: 88,
        averageReferenceQuality: 92,
        averageAlignmentQuality: 90,
        averageValidationQuality: 84,
        dependencyRisks: 2,
        criticalRegions: const ['region-a', 'region-b'],
        metadata: const {'phase': 2},
      );

  test('all analysis and recommendation contracts are available', () async {
    expect(IntelligenceAnalysisType.values, hasLength(10));
    expect(RecommendationType.values, hasLength(15));
    final api = make();
    for (final type in IntelligenceAnalysisType.values) {
      final analysis = await api.builder.build(
        type,
        snapshot(index: type.index),
      );
      expect(analysis.recommendations, hasLength(15));
      expect(analysis.score.overall, inInclusiveRange(0, 100));
    }
    expect(api.engine.analyses, hasLength(10));
    expect(kernel.creates, 0);
  });

  test('recommendations are complete explainable and consultative', () async {
    final api = make(),
        source = snapshot(),
        before = source.toJson(),
        analysis = await api.analyzeProject(source);
    for (final r in analysis.recommendations) {
      expect(r.confidence, inInclusiveRange(0, 1));
      expect(r.explanation, isNotEmpty);
      expect(r.technicalReason, isNotEmpty);
      expect(r.advantages, isNotEmpty);
      expect(r.disadvantages, isNotEmpty);
      expect(r.alternatives, isNotEmpty);
      expect(r.expectedImprovement, inInclusiveRange(0, 100));
      expect(r.affectedFeatures, isNotEmpty);
      expect(r.affectedReferences, isNotEmpty);
      expect(r.affectedRegions, isNotEmpty);
      expect(r.decision, RecommendationDecision.pending);
    }
    expect(source.toJson(), before);
    expect(kernel.creates, 0);
  });

  test('score project health diagnostics and confidence are bounded', () async {
    final analysis = await make().analyzeProject(snapshot());
    final score = analysis.score;
    for (final value in [
      score.modelQuality,
      score.featureQuality,
      score.referenceQuality,
      score.alignmentQuality,
      score.validationQuality,
      score.manufacturability,
      score.maintainability,
      score.editability,
      score.projectHealth,
      score.overall,
    ]) {
      expect(value, inInclusiveRange(0, 100));
    }
    expect(analysis.diagnostics, isNotEmpty);
    expect(analysis.recommendations.first.confidence, inInclusiveRange(0, 1));
  });

  test('accept reject ignore and impact only update local history', () async {
    final api = make(),
        source = snapshot(),
        before = source.toJson(),
        analysis = await api.analyzeProject(source),
        a = analysis.recommendations[0],
        b = analysis.recommendations[1],
        c = analysis.recommendations[2];
    api.advisor.accept(a.id);
    api.advisor.reject(b.id);
    api.advisor.ignore(c.id);
    api.engine.recordImpact(a.id, impact: 4, gain: 3, accuracy: .9);
    expect(
      [a.decision, b.decision, c.decision],
      [
        RecommendationDecision.accepted,
        RecommendationDecision.rejected,
        RecommendationDecision.ignored,
      ],
    );
    expect(api.engine.analytics.accepted, 1);
    expect(api.engine.analytics.rejected, 1);
    expect(api.engine.analytics.ignored, 1);
    expect(api.engine.analytics.observedGain, 3);
    expect(source.toJson(), before);
    expect(() => api.advisor.accept(a.id), throwsStateError);
  });

  test('validation rejects invalid snapshots', () {
    final api = make(),
        invalid = const ProjectKnowledgeSnapshot(
          projectId: '',
          features: -1,
          averageFeatureQuality: 101,
        );
    final result = api.engine.validator.validate(invalid);
    expect(
      result.issues.map((e) => e.type),
      containsAll([
        IntelligenceIssueType.missingProject,
        IntelligenceIssueType.invalidCounts,
        IntelligenceIssueType.invalidQuality,
      ]),
    );
  });

  test(
    '1000 project and feature analyses update score health and diagnostics',
    () async {
      final api = make();
      for (var i = 0; i < 1000; i++) {
        await api.engine.analyzeProject(snapshot(index: i));
        await api.engine.analyzeFeature(snapshot(index: i + 1000));
      }
      expect(api.engine.analytics.projectAnalyses, 1000);
      expect(api.engine.analytics.featureAnalyses, 1000);
      expect(api.engine.analytics.scoreUpdates, 2000);
      expect(api.engine.analytics.healthUpdates, 2000);
      expect(api.engine.analytics.recommendations, 30000);
      expect(api.engine.analytics.diagnostics, greaterThanOrEqualTo(2000));
      expect(api.engine.recommendations, hasLength(30000));
      expect(kernel.creates, 0);
    },
  );

  test('1000 timeline and historical decisions remain project-local', () async {
    final api = make(), source = snapshot(), before = source.toJson();
    for (var i = 0; i < 67; i++) {
      await api.engine.analyzeProject(snapshot(index: i));
    }
    final values = api.recommendations.take(1000).toList();
    for (final recommendation in values) {
      api.advisor.accept(recommendation.id);
    }
    expect(values, hasLength(1000));
    expect(api.engine.analytics.accepted, 1000);
    expect(api.engine.analytics.timelineUpdates, greaterThanOrEqualTo(1000));
    expect(api.engine.analytics.historicalRecords, greaterThanOrEqualTo(1000));
    expect(source.toJson(), before);
  });

  test(
    'graph relates recommendations to features references regions and impact',
    () async {
      final api = make(),
          analysis = await api.analyzeProject(snapshot()),
          recommendation = analysis.recommendations.first;
      expect(
        api.engine.graph.downstream(analysis.id),
        contains(recommendation.id),
      );
      expect(
        api.engine.graph.featureRelations['feature-0'],
        contains(recommendation.id),
      );
      expect(
        api.engine.graph.referenceRelations['reference-0'],
        contains(recommendation.id),
      );
      expect(
        api.engine.graph.validationRelations['region-a'],
        contains(recommendation.id),
      );
      expect(
        api.engine.graph.impactRelations[recommendation.id],
        contains(analysis.id),
      );
    },
  );

  test('repository workspace FEL and passive bootstrap integrate', () async {
    final api = make();
    await api.analyzeProject(snapshot());
    await api.engine.persist();
    for (final path in IntelligenceRepository.paths) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      EngineeringIntelligenceStudioAdapter.workspace,
      'Engineering Intelligence Workspace',
    );
    expect(EngineeringIntelligenceStudioAdapter.panels, hasLength(7));
    expect(
      EngineeringIntelligenceStudioAdapter()
          .buildTree(api.engine, 'project')
          .last
          .context['engineeringIntelligence'],
      isTrue,
    );
    expect(
      createEngineeringIntelligenceFelCommands(api).length,
      greaterThanOrEqualTo(100),
    );
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services
          .get<EngineeringIntelligenceRuntime>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<IntelligenceHistory>(),
      isNotNull,
    );
    expect(
      EngineeringBootstrap.instance.services.get<IntelligenceAnalytics>(),
      isNotNull,
    );
  });
}
