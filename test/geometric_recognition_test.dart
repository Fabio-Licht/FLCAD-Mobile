import 'dart:io';

import 'package:flcad_mobile/core/engineering_decision/api/decision_api.dart';
import 'package:flcad_mobile/core/engineering_decision/engine/engineering_decision_engine.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/geometric_recognition/cache/recognition_cache.dart';
import 'package:flcad_mobile/core/geometric_recognition/candidates/candidate_generator.dart';
import 'package:flcad_mobile/core/geometric_recognition/competition/recognition_competition.dart';
import 'package:flcad_mobile/core/geometric_recognition/confidence/confidence_fusion.dart';
import 'package:flcad_mobile/core/geometric_recognition/engine/geometric_recognition_engine.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/geometric_recognition/pipeline/recognition_pipeline.dart';
import 'package:flcad_mobile/core/geometric_recognition/plugins/recognition_plugin.dart';
import 'package:flcad_mobile/core/geometric_recognition/recognizers/supported_recognizers.dart';
import 'package:flcad_mobile/core/geometric_recognition/runtime/recognition_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

RecognitionContext planeContext({String fingerprint = 'r1'}) =>
    RecognitionContext(
      observation: RecognitionObservation(
        projectId: 'p',
        meshId: 'm',
        regionId: 'r',
        points: const [
          Vector3(0, 0, 2),
          Vector3(1, 0, 2),
          Vector3(0, 1, 2),
          Vector3(1, 1, 2),
          Vector3(.5, .3, 2),
        ],
        normals: const [Vector3(0, 0, 1), Vector3(0, 0, 1)],
        meshFingerprint: 'mesh',
        regionFingerprint: fingerprint,
      ),
      areiConfidence: .8,
      knowledgeConfidence: .7,
      cognitionConfidence: .85,
      decisionConfidence: .75,
      historicalSuccess: .8,
    );

void main() {
  test('candidate generator derives descriptors without fixed dimensions', () {
    final seed = const CandidateGenerator().generate(planeContext());
    expect(
      seed.suggestedTypes,
      containsAll([PrimitiveType.plane, PrimitiveType.sphere]),
    );
    expect(seed.descriptors['planarity'], inInclusiveRange(0, 1));
    expect(seed.descriptors['normalCoherence'], 1);
  });

  test(
    'pipeline recognizes plane, creates DNA, explanation, graph and EDE decision',
    () async {
      final decisions = EngineeringDecisionEngine();
      final engine = GeometricRecognitionEngine(
        decisions: DecisionApi(engine: decisions),
      );
      final progress = <double>[];
      final result = await engine.recognize(
        planeContext(),
        onProgress: progress.add,
      );
      expect(result.winner.type, PrimitiveType.plane);
      expect(result.winner.status, RecognitionStatus.validated);
      expect(result.dna.version, '3.0.0');
      expect(result.dna.geometricSignature, contains('mesh:r1'));
      expect(result.explanation.losingCandidates, isA<List<String>>());
      expect(result.explanation.confidence, greaterThan(0));
      expect(engine.graph.engineeringGraph.nodes, contains(result.id));
      expect(decisions.graph.decisions.single.regionId, 'r');
      expect(progress.last, 1);
    },
  );

  test('sphere fitting wins for symmetric sphere samples', () async {
    final context = RecognitionContext(
      observation: RecognitionObservation(
        projectId: 'p',
        meshId: 'sphere',
        regionId: 'sphere-region',
        points: const [
          Vector3(1, 0, 0),
          Vector3(-1, 0, 0),
          Vector3(0, 1, 0),
          Vector3(0, -1, 0),
          Vector3(0, 0, 1),
          Vector3(0, 0, -1),
          Vector3(.707106, .707106, 0),
        ],
        meshFingerprint: 'sphere-mesh',
        regionFingerprint: 'sphere-region',
      ),
    );
    final result = await GeometricRecognitionEngine().recognize(context);
    expect(result.winner.type, PrimitiveType.sphere);
    expect(result.winner.parameters['radius'], closeTo(1, .001));
  });

  test(
    'insufficient observation becomes unknown rather than fabricated',
    () async {
      final context = RecognitionContext(
        observation: RecognitionObservation(
          projectId: 'p',
          meshId: 'm',
          regionId: 'small',
          points: const [Vector3.zero],
          meshFingerprint: 'm',
          regionFingerprint: 'small',
        ),
      );
      final result = await GeometricRecognitionEngine().recognize(context);
      expect(result.winner.type, PrimitiveType.unknown);
      expect(result.dna.confidence, 0);
      expect(result.explanation.why, contains('Nenhum reconhecedor'));
    },
  );

  test('competition ranks candidates and removes type-region duplicates', () {
    RecognitionCandidate candidate(String id, double score) =>
        RecognitionCandidate(
          id: id,
          type: PrimitiveType.plane,
          regionId: 'r',
          parameters: const {},
          statistics: FitStatistics(
            rms: 1 - score,
            maximum: 1,
            mean: .5,
            coverage: score,
            stability: score,
            score: score,
          ),
          evidence: const [],
          origin: id,
        );
    final result = const RecognitionCompetition().resolve([
      candidate('low', .4),
      candidate('high', .9),
    ]);
    expect(result.winner.id, 'high');
    expect(result.rejectedDuplicates.single.id, 'low');
  });

  test('cache key includes fingerprints and parameters', () {
    final cache = RecognitionCache(), context = planeContext();
    final candidate = const PlaneRecognizer().evaluate(context);
    final result = PrimitiveRecognitionResult(
      id: 'id',
      projectId: 'p',
      meshId: 'm',
      winner: candidate,
      alternatives: const [],
      dna: RecognitionDNA(
        type: PrimitiveType.plane,
        parameters: candidate.parameters,
        regionId: 'r',
        geometricSignature: 'dna',
        quality: 1,
        confidence: 1,
        evidence: const [],
        origin: 'test',
        version: '3',
      ),
      explanation: const RecognitionExplanation(
        why: 'test',
        evidence: [],
        regions: ['r'],
        parameters: {},
        losingCandidates: [],
        score: 1,
        confidence: 1,
      ),
      createdAt: DateTime.utc(2026),
    );
    cache.write(context, result);
    expect(cache.read(context), same(result));
    expect(cache.read(planeContext(fingerprint: 'other')), isNull);
  });

  test('confidence fusion uses multiple signals and not RMS alone', () {
    final context = planeContext(),
        candidate = const PlaneRecognizer().evaluate(context);
    final confidence = const RecognitionConfidenceFusion().fuse(
      context,
      candidate,
    );
    expect(confidence, isNot(candidate.statistics.score));
    expect(confidence, inInclusiveRange(0, 1));
  });

  test('plugins and runtime are replaceable infrastructure', () async {
    final plugins = RecognitionPluginRegistry()
      ..register(const PlaneRecognizer());
    expect(() => plugins.register(const PlaneRecognizer()), throwsStateError);
    expect(await const RecognitionRuntime().run('urf-test', () => 42), 42);
  });

  test('replaceable pipeline records successful stages', () async {
    final pipeline = RecognitionPipeline([_Stage()]);
    expect(await pipeline.run(planeContext(), 1), 2);
    expect(pipeline.traces.single.success, isTrue);
  });

  test('FEL exposes complete recognition vocabulary', () {
    final names = createNativeCommandRegistry(Directory.systemTemp).names;
    for (final name in [
      'RECOGNIZE',
      'RECOGNIZE REGION',
      'LIST PRIMITIVES',
      'SHOW CANDIDATES',
      'SHOW CONFIDENCE',
      'EXPLAIN PRIMITIVE',
      'COMPARE PRIMITIVES',
      'VALIDATE PRIMITIVES',
      'REBUILD RECOGNITION',
      'CLEAR RECOGNITION',
    ]) {
      expect(names, contains(name));
    }
  });
}

class _Stage implements RecognitionPipelineStage<int, int> {
  @override
  String get name => 'test';
  @override
  Future<int> execute(RecognitionContext context, int input) async => input + 1;
}
