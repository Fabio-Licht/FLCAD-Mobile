import 'package:flcad_mobile/core/surface_manufacturing/models/surface_manufacturing_models.dart';
import 'package:flcad_mobile/core/surface_manufacturing/runtime/surface_manufacturing_runtime.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('professional suite exposes all eleven manufacturing strategies', () {
    expect(ManufacturingOperationType.values, hasLength(11));
    expect(
      SurfaceOperationType.values,
      contains(SurfaceOperationType.manufacturingSurface),
    );
  });

  test('100 Draft and Manufacturing analyses remain non-mutating', () {
    for (var i = 0; i < 100; i++) {
      const analysis = ManufacturingAnalysis(
        negativeRegions: 0,
        neutralRegions: 1,
        positiveRegions: 10,
        draftColorMap: {'patch:a': 'positive'},
        draftScore: .9,
        machiningScore: .9,
        stampingScore: .85,
        moldScore: .9,
        electrodeScore: .9,
        quality: .9,
        twistRisk: .1,
        undercutRisk: 0,
      );
      const preview = ManufacturingPreview(
        analysis: analysis,
        affectedRegions: ['patch:a'],
        strategyImpact: {'quality': .9},
      );
      expect(analysis.toJson()['draftScore'], .9);
      expect(analysis.toJson()['manufacturingQuality'], .9);
      expect(preview.toJson()['geometryModified'], isFalse);
    }
  });

  test('Manufacturing Intent is reusable and serializable', () {
    const intent = ManufacturingIntent(
      process: ManufacturingProcess.stamping,
      objective: 'CAM preparation',
      parameters: {'material': 'steel'},
    );
    expect(intent.toJson()['process'], 'stamping');
    expect(intent.toJson()['objective'], 'CAM preparation');
  });

  test('runtime bootstrap is passive and explicit', () async {
    final runtime = SurfaceManufacturingRuntime.instance;
    await runtime.shutdown();
    expect(runtime.isInitialized, isFalse);
    await runtime.initialize();
    expect(runtime.isInitialized, isTrue);
    await runtime.shutdown();
  });
}
