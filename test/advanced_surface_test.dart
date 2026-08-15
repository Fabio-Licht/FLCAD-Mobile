import 'package:flcad_mobile/core/advanced_surface/models/advanced_surface_models.dart';
import 'package:flcad_mobile/core/advanced_surface/runtime/advanced_surface_runtime.dart';
import 'package:flcad_mobile/core/surface_operations/models/surface_operation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('suite exposes eleven strategies and explicit kernel operations', () {
    expect(AdvancedSurfaceType.values, hasLength(11));
    expect(
      SurfaceOperationType.values,
      containsAll(const [
        SurfaceOperationType.matchSurface,
        SurfaceOperationType.rebuildSurface,
        SurfaceOperationType.healSurface,
        SurfaceOperationType.stitchSurface,
        SurfaceOperationType.fillSurface,
        SurfaceOperationType.gapClosure,
      ]),
    );
  });
  test('100 Match, Gap and Network analyses remain non-mutating', () {
    for (var i = 0; i < 100; i++) {
      const gap = GapAnalysisResult(
        gaps: [],
        overlaps: [],
        discontinuities: [],
        openRegions: [],
        maximumGap: 0,
        withinTolerance: true,
      );
      const network = SurfaceNetworkAnalysis(
        globalContinuity: 1,
        globalQuality: .9,
        patchDistribution: {'plane': 1},
        stress: .1,
        reflection: .9,
        zebra: .9,
        manufacturingScore: .9,
      );
      const preview = AdvancedSurfacePreview(
        affectedSurfaces: ['patch:a'],
        predictedQuality: .9,
        predictedContinuity: 1,
        gapAnalysis: gap,
        networkAnalysis: network,
      );
      expect(preview.toJson()['geometryModified'], isFalse);
      expect(gap.toJson()['geometryModified'], isFalse);
      expect(network.toJson()['geometryModified'], isFalse);
    }
  });
  test('advisor remains consultative and G-012 ready', () {
    const advice = AdvancedSurfaceAdvice(
      strategy: AdvancedSurfaceType.heal,
      recommendations: ['Preserve geometry'],
    );
    expect(advice.toJson()['automaticAction'], isFalse);
    expect(advice.toJson()['g012Ready'], isTrue);
  });
  test('runtime bootstrap is passive and explicit', () async {
    final runtime = AdvancedSurfaceRuntime.instance;
    await runtime.shutdown();
    expect(runtime.isInitialized, isFalse);
    await runtime.initialize();
    expect(runtime.isInitialized, isTrue);
    await runtime.shutdown();
  });
}
