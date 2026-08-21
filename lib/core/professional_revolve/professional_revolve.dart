import '../feature_lifecycle/feature_update_solver.dart';
import '../parametric_solver/parametric_solver.dart';

enum RevolveProfileKind { sketch, surface }

enum RevolveAxisKind {
  sketchAxis,
  constructionLine,
  referenceAxis,
  edgePrepared,
  recognizedCylinderPrepared,
  arbitraryPrepared,
}

enum RevolveDirection { counterClockwise, clockwise }

enum RevolveOutput { solid, surface }

class ProfessionalRevolveContract {
  const ProfessionalRevolveContract({
    required this.profileEntityId,
    required this.profileKind,
    required this.profileRevision,
    required this.profileShapeId,
    required this.axisEntityId,
    required this.axisKind,
    required this.axisRevision,
    required this.axisShapeId,
    required this.angleDegrees,
    required this.output,
    this.direction = RevolveDirection.counterClockwise,
  });
  final String profileEntityId, profileShapeId, axisEntityId, axisShapeId;
  final RevolveProfileKind profileKind;
  final RevolveAxisKind axisKind;
  final int profileRevision, axisRevision;
  final double angleDegrees;
  final RevolveDirection direction;
  final RevolveOutput output;
  double get signedAngle =>
      direction == RevolveDirection.clockwise ? -angleDegrees : angleDegrees;
  Map<String, dynamic> toJson() => {
    'profileEntityId': profileEntityId,
    'profileKind': profileKind.name,
    'profileRevision': profileRevision,
    'profileShapeId': profileShapeId,
    'axisEntityId': axisEntityId,
    'axisKind': axisKind.name,
    'axisRevision': axisRevision,
    'axisShapeId': axisShapeId,
    'angleDegrees': angleDegrees,
    'direction': direction.name,
    'output': output.name,
    'symmetricSupported': false,
    'thinSupported': false,
    'upToSurfaceSupported': false,
    'multiAxisSupported': false,
  };
  factory ProfessionalRevolveContract.fromJson(Map<String, dynamic> json) =>
      ProfessionalRevolveContract(
        profileEntityId: json['profileEntityId'] as String,
        profileKind: RevolveProfileKind.values.byName(
          json['profileKind'] as String,
        ),
        profileRevision: (json['profileRevision'] as num).toInt(),
        profileShapeId: json['profileShapeId'] as String,
        axisEntityId: json['axisEntityId'] as String,
        axisKind: RevolveAxisKind.values.byName(json['axisKind'] as String),
        axisRevision: (json['axisRevision'] as num).toInt(),
        axisShapeId: json['axisShapeId'] as String,
        angleDegrees: (json['angleDegrees'] as num).toDouble(),
        direction: RevolveDirection.values.byName(
          json['direction'] as String? ?? 'counterClockwise',
        ),
        output: RevolveOutput.values.byName(json['output'] as String),
      );
}

class ProfessionalRevolveHealth {
  const ProfessionalRevolveHealth(
    this.valid,
    this.axis,
    this.angle,
    this.ready,
    this.message,
  );
  final bool valid, axis, angle, ready;
  final String message;
  Map<String, dynamic> toJson() => {
    'valid': valid,
    'axis': axis,
    'angle': angle,
    'ready': ready,
    'message': message,
  };
}

class ProfessionalRevolveConstraintAdapter {
  const ProfessionalRevolveConstraintAdapter({
    this.featureUpdates = const FeatureUpdateSolver(),
  });
  final FeatureUpdateSolver featureUpdates;
  ParametricMotionPlan solve(ProfessionalRevolveContract value) {
    if (value.profileEntityId.isEmpty || value.profileShapeId.isEmpty) {
      throw ArgumentError('Revolve requires one persistent profile.');
    }
    if (value.axisEntityId.isEmpty ||
        value.axisShapeId.isEmpty ||
        value.axisEntityId == value.profileEntityId) {
      throw ArgumentError('Revolve requires one independent persistent axis.');
    }
    if (!value.angleDegrees.isFinite ||
        value.angleDegrees <= 0 ||
        value.angleDegrees > 360) {
      throw ArgumentError(
        'Revolve angle must be greater than 0° and no greater than 360°.',
      );
    }
    if ({
      RevolveAxisKind.edgePrepared,
      RevolveAxisKind.recognizedCylinderPrepared,
      RevolveAxisKind.arbitraryPrepared,
    }.contains(value.axisKind)) {
      throw UnsupportedError('This axis type is prepared but not implemented.');
    }
    return featureUpdates.update(
      request: ParametricSolveRequest(
        first: value.profileEntityId,
        second: value.axisEntityId,
        degreesOfFreedom: [
          ParametricDegreeOfFreedom(value.profileEntityId),
          ParametricDegreeOfFreedom(value.axisEntityId),
        ],
        restrictions: [
          ParametricRestriction('revolve.profile', {value.profileEntityId}),
          ParametricRestriction('revolve.axis', {value.axisEntityId}),
        ],
        priorities: [
          ParametricPriority(value.profileEntityId, 0),
          ParametricPriority(value.axisEntityId, 1),
        ],
        preferredAnchor: value.profileEntityId,
      ),
      apply: (plan) => plan,
    );
  }

  ProfessionalRevolveHealth health(ProfessionalRevolveContract value) {
    try {
      solve(value);
      return const ProfessionalRevolveHealth(
        true,
        true,
        true,
        true,
        'Revolve is ready.',
      );
    } on Object catch (error) {
      return ProfessionalRevolveHealth(
        value.profileShapeId.isNotEmpty,
        value.axisShapeId.isNotEmpty,
        value.angleDegrees > 0 && value.angleDegrees <= 360,
        false,
        '$error',
      );
    }
  }
}

abstract final class ProfessionalRevolveNaming {
  static String nextId(Iterable<String> ids) {
    final used = ids.toSet();
    var index = 1;
    while (used.contains('Revolve${index.toString().padLeft(3, '0')}')) {
      index++;
    }
    return 'Revolve${index.toString().padLeft(3, '0')}';
  }
}
