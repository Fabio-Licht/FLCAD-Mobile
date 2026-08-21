import 'dart:io';

import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/feature_lifecycle/feature_lifecycle.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/geometric_recognition/models/recognition_models.dart';
import 'package:flcad_mobile/core/professional_recognition/models/professional_recognition_models.dart';
import 'package:flcad_mobile/core/recognition_engine/recognition_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = RecognitionResultAdapter();
  const points = [
    Vector3(1, 0, -2),
    Vector3(-1, 0, -2),
    Vector3(1, 0, 2),
    Vector3(-1, 0, 2),
  ];

  test('generic result exposes professional plane knowledge only', () {
    final result = adapter.build(
      id: 'Recognition001',
      meshId: 'Mesh001',
      regionId: 'region:1',
      points: points,
      area: 8,
      primitive: _primitive(PrimitiveType.plane, {
        'origin': [0, 0, 0],
        'normal': [0, 1, 0],
      }),
    );
    expect(result.type, RecognitionResultType.plane);
    expect(result.parameters['area'], 8);
    expect(result.parameters['normal'], [0, 1, 0]);
    expect(result.parameters['maximumDeviation'], .01);
    expect(result.confidence, .98);
    expect(result.toJson(), isNot(contains('sketch')));
    expect(result.toJson(), isNot(contains('surface')));
  });

  test('cylinder result derives diameter and axial length', () {
    final result = adapter.build(
      id: 'Recognition002',
      meshId: 'Mesh001',
      regionId: 'region:2',
      points: points,
      area: 20,
      primitive: _primitive(PrimitiveType.cylinder, {
        'origin': [0, 0, 0],
        'axis': [0, 0, 1],
        'radius': 1.0,
      }),
    );
    expect(result.type, RecognitionResultType.cylinder);
    expect(result.parameters['diameter'], 2);
    expect(result.parameters['length'], 4);
  });

  test('cone, sphere and first fillet contract retain measured parameters', () {
    final cone = adapter.build(
      id: 'Recognition003',
      meshId: 'Mesh001',
      regionId: 'region:3',
      points: points,
      area: 12,
      primitive: _primitive(PrimitiveType.cone, {
        'origin': [0, 0, 0],
        'axis': [0, 0, 1],
        'referenceRadius': 2.0,
        'halfAngle': .5,
      }),
    );
    final sphere = adapter.build(
      id: 'Recognition004',
      meshId: 'Mesh001',
      regionId: 'region:4',
      points: points,
      area: 12,
      primitive: _primitive(PrimitiveType.sphere, {
        'center': [0, 0, 0],
        'radius': 10.0,
      }),
    );
    final fillet = adapter.build(
      id: 'Recognition005',
      meshId: 'Mesh001',
      regionId: 'region:5',
      points: points,
      area: 12,
      primitive: _primitive(PrimitiveType.torus, {
        'center': [0, 0, 0],
        'axis': [0, 0, 1],
        'majorRadius': 20.0,
        'minorRadius': 2.5,
      }),
    );
    expect(cone.type, RecognitionResultType.cone);
    expect(cone.parameters['angleDegrees'], closeTo(28.6479, .001));
    expect(sphere.type, RecognitionResultType.sphere);
    expect(sphere.parameters['radius'], 10);
    expect(fillet.type, RecognitionResultType.fillet);
    expect(fillet.parameters['meanRadius'], 2.5);
    expect(fillet.parameters['minimumRadius'], 2.49);
    expect(fillet.parameters['maximumRadius'], 2.51);
  });

  test(
    'low confidence becomes freeform with surface reconstruction advice',
    () {
      final result = adapter.build(
        id: 'Recognition006',
        meshId: 'Mesh001',
        regionId: 'region:6',
        points: points,
        area: 7,
        primitive: _primitive(PrimitiveType.plane, {
          'origin': [0, 0, 0],
          'normal': [0, 1, 0],
        }, confidence: .4),
      );
      expect(result.type, RecognitionResultType.freeform);
      expect(result.suggestion, 'Reconstruction by Surface');
      expect(RecognitionResult.fromJson(result.toJson()).id, result.id);
    },
  );

  test(
    'Recognition Result preserves id, history and mesh relation on reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('flcad_g135_');
      addTearDown(() => directory.delete(recursive: true));
      final runtime = CadRuntime(kernels: KernelManager());
      addTearDown(runtime.dispose);
      await runtime.open('project', directory);
      final result = adapter.build(
        id: 'Recognition001',
        meshId: 'Mesh001',
        regionId: 'region:persistent',
        points: points,
        area: 8,
        primitive: _primitive(PrimitiveType.plane, {
          'origin': [0, 0, 0],
          'normal': [0, 1, 0],
        }),
        history: const ['recognition evaluated'],
      );
      await runtime.mutate(
        command: 'recognition-result.create',
        upsert: [
          CadDocumentEntity(
            id: result.id,
            kind: CadDocumentEntityKind.recognition,
            data: {
              'authoringRoot': true,
              'authoringWorkspace': 'Recognition',
              'references': [result.meshId],
              'dependencies': [result.meshId],
              'recognitionResult': result.toJson(),
            },
          ),
        ],
      );
      await runtime.save(recordLifecycle: true);
      await runtime.close();
      await runtime.open('project', directory);
      final restored = runtime.document!.entities[result.id]!;
      final knowledge = RecognitionResult.fromJson(
        Map<String, dynamic>.from(restored.data['recognitionResult'] as Map),
      );
      expect(restored.kind, CadDocumentEntityKind.recognition);
      expect(knowledge.id, result.id);
      expect(knowledge.meshId, 'Mesh001');
      expect(knowledge.history, ['recognition evaluated']);
      expect(FeatureLifecycleContract.require(restored).featureId, result.id);
    },
  );
}

ProfessionalPrimitive _primitive(
  PrimitiveType type,
  Map<String, dynamic> parameters, {
  double confidence = .98,
}) {
  const statistics = FitStatistics(
    rms: .004,
    maximum: .01,
    mean: .003,
    coverage: .99,
    stability: .98,
    score: .97,
  );
  final candidate = RecognitionCandidate(
    id: 'candidate:${type.name}',
    type: type,
    regionId: 'region',
    parameters: parameters,
    statistics: statistics,
    evidence: const [],
    origin: 'test',
  );
  final result = PrimitiveRecognitionResult(
    id: 'recognition:${type.name}',
    projectId: 'project',
    meshId: 'Mesh001',
    winner: candidate,
    alternatives: const [],
    dna: RecognitionDNA(
      type: type,
      parameters: parameters,
      regionId: 'region',
      geometricSignature: type.name,
      quality: .97,
      confidence: confidence,
      evidence: const [],
      origin: 'test',
      version: '1',
    ),
    explanation: RecognitionExplanation(
      why: 'best fit',
      evidence: const [],
      regions: const ['region'],
      parameters: parameters,
      losingCandidates: const [],
      score: .97,
      confidence: confidence,
    ),
    createdAt: DateTime.utc(2026),
  );
  return ProfessionalPrimitive(
    recognition: result,
    residualMap: const ResidualMap([], [], []),
    pass: 1,
    auditTrail: const ['evaluated'],
  );
}
