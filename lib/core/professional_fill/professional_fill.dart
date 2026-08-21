enum FillBoundaryContinuity { g0, g1, g2Prepared }

class FillBoundaryCondition {
  const FillBoundaryCondition({
    required this.boundaryEntityId,
    required this.boundaryShapeId,
    required this.loopId,
    this.revision = 0,
    this.continuity = FillBoundaryContinuity.g0,
    this.influence = 1,
    this.supportSurfaceId,
    this.supportShapeId,
  });

  final String boundaryEntityId, boundaryShapeId, loopId;
  final int revision;
  final FillBoundaryContinuity continuity;
  final double influence;
  final String? supportSurfaceId, supportShapeId;

  void validate() {
    if (boundaryEntityId.isEmpty || boundaryShapeId.isEmpty || loopId.isEmpty) {
      throw ArgumentError('Fill boundary identity and loop are required.');
    }
    if (!influence.isFinite || influence <= 0 || influence > 1) {
      throw ArgumentError('Fill boundary influence must be in (0, 1].');
    }
    if (continuity == FillBoundaryContinuity.g2Prepared) {
      throw UnsupportedError('Fill G2 is prepared but not implemented.');
    }
    if (continuity == FillBoundaryContinuity.g1 &&
        (supportSurfaceId == null || supportShapeId == null)) {
      throw ArgumentError(
        'Fill G1 requires a support Surface for the boundary.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'boundaryEntityId': boundaryEntityId,
    'boundaryShapeId': boundaryShapeId,
    'loopId': loopId,
    'revision': revision,
    'continuity': continuity.name,
    'influence': influence,
    'supportSurfaceId': supportSurfaceId,
    'supportShapeId': supportShapeId,
  };

  factory FillBoundaryCondition.fromJson(Map<String, dynamic> json) =>
      FillBoundaryCondition(
        boundaryEntityId: json['boundaryEntityId'] as String,
        boundaryShapeId: json['boundaryShapeId'] as String,
        loopId: json['loopId'] as String? ?? 'outer',
        revision: (json['revision'] as num?)?.toInt() ?? 0,
        continuity: FillBoundaryContinuity.values.byName(
          json['continuity'] as String? ?? 'g0',
        ),
        influence: (json['influence'] as num?)?.toDouble() ?? 1,
        supportSurfaceId: json['supportSurfaceId'] as String?,
        supportShapeId: json['supportShapeId'] as String?,
      );
}

abstract final class ProfessionalFillNaming {
  static String nextId(Iterable<String> ids) {
    final used = ids.toSet();
    var sequence = 1;
    while (used.contains('Fill${sequence.toString().padLeft(3, '0')}')) {
      sequence++;
    }
    return 'Fill${sequence.toString().padLeft(3, '0')}';
  }
}
