import 'package:flcad_mobile/core/professional_continuity/professional_continuity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ProfessionalContinuityEngine();

  test('G0 objectively distinguishes shared and disconnected boundaries', () {
    final shared = engine.inspectG0(
      _surface('Surface001', {'Edge:shared', 'Edge:a'}),
      _surface('Surface002', {'Edge:shared', 'Edge:b'}),
    );
    expect(shared.level, ProfessionalContinuityLevel.g0);
    expect(shared.sharedBoundaryIds, ['Edge:shared']);
    expect(shared.g0, isTrue);

    final disconnected = engine.inspectG0(
      _surface('Surface001', {'Edge:a'}),
      _surface('Surface002', {'Edge:b'}),
    );
    expect(disconnected.level, ProfessionalContinuityLevel.disconnected);
    expect(disconnected.g0, isFalse);
    expect(disconnected.quality, 0);
  });

  test('G1 requires preview and preserves the anchored surface', () {
    final preview = engine.previewG1(
      _surface('Surface001', {'Edge:shared'}),
      _surface('Surface002', {'Edge:shared'}),
    );
    expect(preview.level, ProfessionalContinuityLevel.g1);
    expect(preview.confirmed, isFalse);
    expect(
      () => engine.confirmG1(preview, previousRevision: 4),
      returnsNormally,
    );
    final confirmed = engine.confirmG1(preview, previousRevision: 4);
    expect(confirmed.id, preview.id);
    expect(confirmed.confirmed, isTrue);
    expect(confirmed.revision, 5);
    expect(confirmed.firstSurfaceId, 'Surface001');
    expect(confirmed.secondSurfaceId, 'Surface002');
  });

  test('G1 refuses surfaces without positional continuity', () {
    expect(
      () => engine.previewG1(
        _surface('Surface001', {'Edge:a'}),
        _surface('Surface002', {'Edge:b'}),
      ),
      throwsStateError,
    );
  });

  test('relation and independent analysis states survive serialization', () {
    final confirmed = engine.confirmG1(
      engine.previewG1(
        _surface('Surface001', {'Edge:shared'}),
        _surface('Surface002', {'Edge:shared'}),
      ),
    );
    final restored = SurfaceContinuityRelation.fromJson(confirmed.toJson());
    expect(restored.id, 'Continuity:Surface001:Surface002');
    expect(restored.g1, isTrue);
    expect(restored.toJson()['g2Supported'], isFalse);
    expect(
      restored.toJson()['solverContract'],
      'flcad.geometry-constraint-solver/v1',
    );

    final settings = [
      const SurfaceAnalysisSetting(
        kind: ProfessionalAnalysisKind.zebra,
        enabled: true,
        intensity: 0.4,
      ),
      const SurfaceAnalysisSetting(
        kind: ProfessionalAnalysisKind.reflection,
        enabled: false,
        intensity: 0.6,
      ),
      const SurfaceAnalysisSetting(
        kind: ProfessionalAnalysisKind.curvature,
        enabled: true,
        intensity: 0.8,
      ),
    ];
    final roundTrip = settings
        .map((item) => SurfaceAnalysisSetting.fromJson(item.toJson()))
        .toList();
    expect(roundTrip.where((item) => item.enabled).map((item) => item.kind), [
      ProfessionalAnalysisKind.zebra,
      ProfessionalAnalysisKind.curvature,
    ]);
    expect(roundTrip.last.intensity, 0.8);
  });
}

ContinuitySurfaceReference _surface(String id, Set<String> boundaries) =>
    ContinuitySurfaceReference(
      id: id,
      shapeId: 'shape:$id',
      boundaryIds: boundaries,
      revision: 1,
    );
