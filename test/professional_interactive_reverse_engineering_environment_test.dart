import 'package:flcad_mobile/app/modeling/modeling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const region = ModelingSelection(
    id: 'region-1',
    name: 'Planar region 1',
    type: ModelingSelectionType.meshRegion,
    evidence: ['42 selected triangles'],
  );

  test('viewport supports replace ctrl shift highlight and explorer sync', () {
    final viewport = ModelingViewportController();
    viewport.select(region);
    expect(viewport.highlight.contains('region-1'), isTrue);
    const second = ModelingSelection(
      id: 'region-2',
      name: 'Region 2',
      type: ModelingSelectionType.meshRegion,
    );
    viewport.select(second, modifier: SelectionModifier.shift);
    expect(viewport.selection, hasLength(2));
    viewport.select(region, modifier: SelectionModifier.control);
    expect(viewport.selection.single.id, 'region-2');
    const face = ModelingSelection(
      id: 'face-1',
      name: 'Face 1',
      type: ModelingSelectionType.face,
    );
    ExplorerSync(viewport).select(face);
    expect(viewport.selection.single.id, 'face-1');
  });

  test('camera orbit pan zoom are incremental and fit is deterministic', () {
    final viewport = ModelingViewportController();
    viewport.orbit(2, 3);
    viewport.pan(4, 5);
    viewport.zoom(2);
    expect(viewport.camera.orbitX, 2);
    expect(viewport.camera.panY, 5);
    expect(viewport.camera.zoom, 2);
    viewport.navigation.fit();
    expect(viewport.camera.zoom, 1);
  });

  test(
    'complete selection preview parameters confirmation flow commits once',
    () async {
      final viewport = ModelingViewportController()..select(region);
      var commits = 0;
      final registry = ToolRegistry()
        ..register(
          ActiveTool(
            id: 'surface.plane',
            label: 'Planar Surface',
            allowedSelection: const {ModelingSelectionType.meshRegion},
            defaultParameters: const {'tolerance': .01},
            previewBuilder: (selection, parameters) async => EngineeringPreview(
              id: 'preview-plane',
              kind: 'plane',
              sourceIds: selection.map((e) => e.id).toList(),
              parameters: parameters,
              evidence: const ['certified plane hypothesis'],
              confidence: .98,
              justification: 'Lowest residual certified hypothesis.',
            ),
            commit: (_) async => ++commits,
          ),
        );
      final manager = InteractionManager(
        viewport: viewport,
        tools: ToolManager(registry),
      );
      manager.synchronizeSelection();
      await manager.activate('surface.plane');
      expect(manager.context.stage, InteractionStage.awaitingConfirmation);
      expect(viewport.previewLayer.visible, isTrue);
      await manager.setParameter('tolerance', .02);
      expect(manager.context.preview!.parameters['tolerance'], .02);
      expect(commits, 0);
      await manager.confirm();
      expect(commits, 1);
      expect(viewport.previewLayer.visible, isFalse);
      expect(manager.context.stage, InteractionStage.committed);
    },
  );

  test(
    'commit without preview is forbidden and cancellation never commits',
    () async {
      final viewport = ModelingViewportController()..select(region);
      final registry = ToolRegistry()
        ..register(
          ActiveTool(
            id: 'recognition.plane',
            label: 'Detect Plane',
            allowedSelection: const {ModelingSelectionType.meshRegion},
            defaultParameters: const {'tolerance': .01},
            previewBuilder: (_, parameters) async => EngineeringPreview(
              id: 'p',
              kind: 'plane',
              sourceIds: const ['region-1'],
              parameters: parameters,
              evidence: const ['engine evidence'],
              confidence: .9,
              justification: 'Certified recognition result.',
            ),
            commit: (_) async => fail('cancelled tool must not commit'),
          ),
        );
      final manager = InteractionManager(
        viewport: viewport,
        tools: ToolManager(registry),
      );
      await expectLater(manager.confirm(), throwsStateError);
      await manager.activate('recognition.plane');
      manager.cancel();
      expect(manager.context.stage, InteractionStage.cancelled);
      expect(viewport.preview, isNull);
    },
  );

  test('invalid parameters and evidence-free previews are rejected', () async {
    final tool = ActiveTool(
      id: 'invalid',
      label: 'Invalid',
      allowedSelection: const {ModelingSelectionType.meshRegion},
      defaultParameters: const {},
      previewBuilder: (_, parameters) async => EngineeringPreview(
        id: 'invalid',
        kind: 'plane',
        sourceIds: const ['r'],
        parameters: parameters,
        evidence: const [],
        confidence: .8,
        justification: 'none',
      ),
      commit: (_) async => null,
    );
    await expectLater(
      const EngineeringPreviewEngine().build(
        tool,
        const [region],
        const {'tolerance': -1.0},
      ),
      throwsStateError,
    );
    await expectLater(
      const EngineeringPreviewEngine().build(
        tool,
        const [region],
        const {'tolerance': .1},
      ),
      throwsStateError,
    );
  });

  test('REV.2 capability registry exposes only end-to-end integrations', () {
    const registry = ModelingCapabilityRegistry();
    expect(registry.require('selection.document').mayBeExposed, isTrue);
    expect(registry.require('preview.confirmation').mayBeExposed, isTrue);
    expect(
      registry.require('recognition.analytic').status,
      ModelingCapabilityStatus.requiresInteractionAdapter,
    );
    expect(
      registry.require('sketch.3d').status,
      ModelingCapabilityStatus.engineUnavailable,
    );
    expect(registry.exposed.map((e) => e.id), [
      'selection.document',
      'preview.confirmation',
    ]);
    expect(
      ModelingCapabilityRegistry.capabilities.every(
        (e) => e.engine.isNotEmpty && e.requirement.isNotEmpty,
      ),
      isTrue,
    );
  });
}
