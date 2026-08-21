import 'dart:io';

import 'package:flcad_mobile/app/cad_viewport/rendering/recognition_surface_preview_builder.dart';
import 'package:flcad_mobile/app/engineering_bridge/adapters/recognition_surface_assistant_adapter.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/recognition_engine/recognition_result.dart';
import 'package:flcad_mobile/core/surface_assistant/surface_assistant.dart';
import 'package:flcad_mobile/core/surface_generation/api/surface_generation_api.dart';
import 'package:flcad_mobile/core/surface_generation/engine/surface_generation_engine.dart';
import 'package:flcad_mobile/core/surface_generation/repository/surface_generation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assistant = IntelligentSurfaceAssistant();
  const preview = RecognitionSurfacePreviewBuilder();

  test(
    'assistant consumes only a Recognition Result and maps analytic strategy',
    () {
      final result = _result(RecognitionResultType.plane, {
        'origin': [0, 0, 0],
        'normal': [0, 0, 1],
        'area': 100,
        'maximumDeviation': .012,
      });
      final suggestion = assistant.suggest(result);
      expect(suggestion.recognitionResultId, 'Recognition001');
      expect(suggestion.strategy, SurfaceAssistantStrategy.planarSurface);
      expect(suggestion.canCreate, isTrue);
      expect(suggestion.parameters['maximumDeviation'], .012);
    },
  );

  test('all analytic Recognition types receive a non-persistent preview', () {
    final values = <RecognitionResult>[
      _result(RecognitionResultType.plane, {
        'origin': [0, 0, 0],
        'normal': [0, 0, 1],
        'area': 25,
      }),
      _result(RecognitionResultType.cylinder, {
        'origin': [0, 0, 0],
        'axis': [0, 0, 1],
        'radius': 2,
        'length': 10,
      }),
      _result(RecognitionResultType.cone, {
        'origin': [0, 0, 0],
        'axis': [0, 0, 1],
        'radius': 4,
        'length': 8,
      }),
      _result(RecognitionResultType.sphere, {
        'center': [0, 0, 0],
        'radius': 3,
      }),
      _result(RecognitionResultType.fillet, {
        'center': [0, 0, 0],
        'axis': [0, 0, 1],
        'majorRadius': 8,
        'minorRadius': 1,
      }),
    ];
    for (final result in values) {
      final visual = preview.build(result, assistant.suggest(result));
      expect(visual.id, 'surface-assistant-preview');
      expect(visual.transparent, isTrue);
      expect(visual.geometry['previewOnly'], isTrue);
      expect(visual.geometry['sourceRecognitionId'], result.id);
      expect(visual.geometry['nodes'], isNotEmpty);
      expect(visual.geometry['triangles'], isNotEmpty);
    }
  });

  test('low confidence cannot create and remains an operator decision', () {
    final suggestion = assistant.suggest(
      _result(RecognitionResultType.sphere, {
        'center': [0, 0, 0],
        'radius': 3,
      }, confidence: .4),
    );
    expect(suggestion.canCreate, isFalse);
  });

  test(
    'freeform proposes supervised strategies but cannot create in G-136',
    () {
      final result = _result(RecognitionResultType.freeform, {
        'area': 120,
        'pointCount': 800,
      });
      final suggestion = assistant.suggest(result);
      expect(suggestion.strategy, SurfaceAssistantStrategy.freeSurface);
      expect(
        suggestion.alternatives,
        containsAll([
          SurfaceAssistantStrategy.loft,
          SurfaceAssistantStrategy.sweep,
          SurfaceAssistantStrategy.networkSurface,
        ]),
      );
      expect(suggestion.canCreate, isFalse);
      final visual = preview.build(result, suggestion);
      expect(visual.geometry['previewOnly'], isTrue);
      expect(visual.geometry['nodes'], isEmpty);
    },
  );

  test(
    'explicit confirmation uses Surface001 and preserves Recognition provenance',
    () async {
      final directory = await Directory.systemTemp.createTemp('flcad_g136_');
      addTearDown(() => directory.delete(recursive: true));
      final api = SurfaceGenerationApi(
        SurfaceGenerationEngine(
          projectId: 'project',
          kernel: _AssistantKernel(),
          repository: SurfaceGenerationRepository(directory),
        ),
      );
      final recognition = _result(RecognitionResultType.plane, {
        'origin': [0, 0, 0],
        'normal': [0, 0, 1],
        'area': 100,
      });
      final surface = await const RecognitionSurfaceAssistantAdapter().confirm(
        featureId: 'Surface001',
        recognition: recognition,
        suggestion: assistant.suggest(recognition),
        generation: api,
      );
      expect(surface.surfaceId, 'Surface001');
      expect(surface.origin, 'surface-assistant');
      expect(surface.parameters['sourceRecognitionId'], 'Recognition001');
      expect(surface.evidenceIds, contains('Recognition001'));
      expect(surface.parameters['topology'], isA<Map>());
    },
  );
}

RecognitionResult _result(
  RecognitionResultType type,
  Map<String, dynamic> parameters, {
  double confidence = .96,
}) => RecognitionResult(
  id: 'Recognition001',
  type: type,
  meshId: 'Mesh001',
  regionId: 'region:1',
  confidence: confidence,
  parameters: parameters,
  quality: 'RMS .01',
  suggestion: 'Review',
  createdAt: DateTime.utc(2026),
);

class _AssistantKernel implements InterchangeGeometryKernelAPI {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'assistant-kernel',
    name: 'Assistant test kernel',
    version: '1',
    vendor: 'test',
    capabilities: KernelCapabilities({KernelCapability.planeSurface}),
  );

  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ok', DateTime.now());
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async => ShapeHandle.reference(
    persistentId: persistentId,
    kernelId: descriptor.id,
    type: expectedType,
    fingerprint: 'fp:$persistentId',
  );
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<List<GeometryDiagnostic>> diagnose(ShapeHandle handle) async =>
      const [];
  @override
  Future<List<HealingProposal>> proposeHealing(ShapeHandle handle) async =>
      const [];
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
  @override
  Future<ShapeHandle> importFile(
    String path,
    KernelExchangeFormat format, {
    required String projectId,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => throw UnimplementedError();
  @override
  Future<void> exportFile(
    ShapeHandle handle,
    String path,
    KernelExchangeFormat format, {
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => throw UnimplementedError();
  @override
  Future<ShapeHandle> sew(
    List<ShapeHandle> faces, {
    required String projectId,
    required double tolerance,
  }) => throw UnimplementedError();
  @override
  Future<KernelMeshResult> mesh(
    ShapeHandle handle, {
    required String outputPath,
    required double deflection,
  }) => throw UnimplementedError();
}
