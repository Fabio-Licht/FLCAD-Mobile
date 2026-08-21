import 'package:flcad_mobile/core/professional_sew/professional_sew.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sew accepts multiple Surfaces and never creates a Solid', () {
    const contract = ProfessionalSewContract(
      surfaceEntityIds: ['Surface001', 'Surface002', 'Surface003'],
      tolerance: .05,
      gaps: SewGapAnalysis(
        minimum: .005,
        maximum: .018,
        average: .011,
        coincidentEdges: 2,
        incompatibleRegions: 0,
      ),
    );
    contract.validate();
    expect(contract.closed, isFalse);
    expect(contract.toJson()['createsSolid'], isFalse);
    expect(contract.toJson()['surfacesPreserved'], isTrue);
  });

  test('gap outside tolerance requires explicit compensation', () {
    const rejected = ProfessionalSewContract(
      surfaceEntityIds: ['Surface001', 'Surface002'],
      tolerance: .05,
      gaps: SewGapAnalysis(
        minimum: .01,
        maximum: .52,
        average: .2,
        coincidentEdges: 0,
        incompatibleRegions: 1,
      ),
    );
    expect(rejected.validate, throwsStateError);
    final accepted = ProfessionalSewContract.fromJson({
      ...rejected.toJson(),
      'compensate': true,
    });
    accepted.validate();
  });

  test('Partial Unsew preserves original member identities', () {
    const contract = ProfessionalSewContract(
      surfaceEntityIds: ['Surface001', 'Surface002', 'Surface003'],
      state: SewRelationState.partiallyUnsewed,
      detachedSurfaceIds: ['Surface002'],
    );
    expect(contract.attachedSurfaceIds, ['Surface001', 'Surface003']);
    expect(contract.surfaceEntityIds, contains('Surface002'));
    expect(
      ProfessionalSewContract.fromJson(contract.toJson()).surfaceEntityIds,
      contract.surfaceEntityIds,
    );
  });

  test('Body identity naming is stable and collision free', () {
    expect(ProfessionalSewNaming.nextId(const []), 'Body001');
    expect(
      ProfessionalSewNaming.nextId(const ['Body001', 'Body003']),
      'Body002',
    );
  });
}
