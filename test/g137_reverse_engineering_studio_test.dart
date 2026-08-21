import 'dart:io';

import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_document/cad_document.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/reverse_engineering_studio/reverse_engineering_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const studio = ReverseEngineeringStudioEngine();

  test('integrates progress and persistent provenance into one workflow', () {
    final entities = _workflowEntities();
    final state = studio.evaluate(entities, selectedEntityId: 'Surface001');
    expect(
      state.steps
          .where(
            (step) => step.status == ReverseEngineeringStageStatus.completed,
          )
          .map((step) => step.stage),
      containsAll([
        ReverseEngineeringStage.mesh,
        ReverseEngineeringStage.recognition,
        ReverseEngineeringStage.referenceCurves,
        ReverseEngineeringStage.sketch,
        ReverseEngineeringStage.surface,
        ReverseEngineeringStage.topology,
      ]),
    );
    expect(state.currentStage, ReverseEngineeringStage.solid);
    expect(state.nextAction, 'Surface Operations');
    expect(state.timelines.single.entityIds, [
      'Surface001',
      'Sketch001',
      'ReferenceCurve001',
      'Recognition001',
      'Mesh001',
    ]);
  });

  test('context awareness recommends the correct existing module', () {
    final entities = _workflowEntities();
    expect(
      studio.evaluate(entities, selectedEntityId: 'Mesh001').nextAction,
      'Recognition',
    );
    expect(
      studio.evaluate(entities, selectedEntityId: 'Recognition001').nextAction,
      'Surface Assistant',
    );
    expect(
      studio
          .evaluate(entities, selectedEntityId: 'ReferenceCurve001')
          .nextAction,
      'Sketch Assistant',
    );
    expect(
      studio.evaluate(entities, selectedEntityId: 'Sketch001').nextAction,
      'Surface Preview',
    );
    expect(
      studio.evaluate(entities, selectedEntityId: 'Surface001').nextAction,
      'Surface Operations',
    );
  });

  test('empty project explains the blocker without executing an action', () {
    final state = studio.evaluate(const []);
    expect(state.currentStage, ReverseEngineeringStage.mesh);
    expect(state.nextAction, 'Import Mesh');
    expect(state.blockReason, 'No mesh is loaded.');
  });

  test('Studio snapshot survives save and reopen unchanged', () async {
    final directory = await Directory.systemTemp.createTemp('flcad_g137_');
    addTearDown(() => directory.delete(recursive: true));
    final runtime = CadRuntime(kernels: KernelManager());
    addTearDown(runtime.dispose);
    await runtime.open('project', directory);
    final state = studio.evaluate(
      _workflowEntities(),
      selectedEntityId: 'Surface001',
    );
    await runtime.mutate(
      command: 'reverse-engineering-studio.refresh',
      upsert: [
        CadDocumentEntity(
          id: 'ReverseEngineeringStudio',
          kind: CadDocumentEntityKind.collection,
          data: {
            'hiddenFromExplorer': true,
            'workspaceState': state.toJson(),
            'sceneVisible': false,
          },
        ),
      ],
    );
    await runtime.save();
    await runtime.close();
    await runtime.open('project', directory);
    final restored = runtime.document!.entities['ReverseEngineeringStudio']!;
    final raw = restored.data['workspaceState'] as Map;
    expect(raw['currentStage'], 'solid');
    expect(
      (raw['timelines'] as List).single['entityIds'],
      state.timelines.single.entityIds,
    );
    expect(restored.data['hiddenFromExplorer'], isTrue);
  });
}

List<CadDocumentEntity> _workflowEntities() => [
  const CadDocumentEntity(
    id: 'Mesh001',
    kind: CadDocumentEntityKind.import,
    mesh: KernelMeshHandle(
      persistentId: 'mesh',
      kernelId: 'test',
      fingerprint: 'mesh',
      vertexCount: 4,
      triangleCount: 2,
      bounds: KernelBounds(0, 0, 0, 1, 1, 1),
      hasNormals: false,
      metadata: {},
    ),
    data: {'name': 'Mesh001'},
  ),
  const CadDocumentEntity(
    id: 'Recognition001',
    kind: CadDocumentEntityKind.recognition,
    data: {
      'recognitionResult': {'meshId': 'Mesh001'},
      'references': ['Mesh001'],
    },
  ),
  const CadDocumentEntity(
    id: 'ReferenceCurve001',
    kind: CadDocumentEntityKind.section,
    data: {
      'referenceCurve': true,
      'section': {'meshId': 'Mesh001'},
    },
  ),
  const CadDocumentEntity(
    id: 'Sketch001',
    kind: CadDocumentEntityKind.sketch,
    data: {
      'sketch': {
        'metadata': {'sourceSectionId': 'ReferenceCurve001'},
      },
    },
  ),
  const CadDocumentEntity(
    id: 'Surface001',
    kind: CadDocumentEntityKind.surface,
    data: {
      'parameters': {'sourceSketchId': 'Sketch001'},
      'surface': {},
    },
  ),
  const CadDocumentEntity(
    id: 'Edge001',
    kind: CadDocumentEntityKind.edge,
    data: {'parentSurfaceId': 'Surface001'},
  ),
];
