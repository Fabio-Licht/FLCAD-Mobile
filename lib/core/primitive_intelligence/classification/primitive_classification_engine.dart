import '../../geometric_recognition/models/recognition_models.dart';
import '../models/primitive_intelligence_models.dart';

class PrimitiveClassificationPolicy {
  const PrimitiveClassificationPolicy({
    this.largeArea = 100,
    this.deepCylinderRatio = 2,
    this.draftMaximumDegrees = 15,
  });
  final double largeArea, deepCylinderRatio, draftMaximumDegrees;
}

class PrimitiveClassificationEngine {
  const PrimitiveClassificationEngine({
    this.policy = const PrimitiveClassificationPolicy(),
  });
  final PrimitiveClassificationPolicy policy;
  List<PrimitiveFunction> supportedFunctions(PrimitiveType type) =>
      switch (type) {
        PrimitiveType.plane => const [
          PrimitiveFunction.base,
          PrimitiveFunction.support,
          PrimitiveFunction.reference,
          PrimitiveFunction.symmetry,
          PrimitiveFunction.machining,
          PrimitiveFunction.free,
        ],
        PrimitiveType.cylinder => const [
          PrimitiveFunction.mainAxis,
          PrimitiveFunction.hole,
          PrimitiveFunction.guide,
          PrimitiveFunction.bearing,
          PrimitiveFunction.reference,
          PrimitiveFunction.revolution,
        ],
        PrimitiveType.cone => const [
          PrimitiveFunction.draft,
          PrimitiveFunction.centering,
          PrimitiveFunction.tool,
          PrimitiveFunction.seat,
        ],
        PrimitiveType.sphere => const [
          PrimitiveFunction.joint,
          PrimitiveFunction.reference,
          PrimitiveFunction.support,
        ],
        PrimitiveType.torus => const [
          PrimitiveFunction.functionalRadius,
          PrimitiveFunction.revolution,
          PrimitiveFunction.reference,
        ],
        _ => const [PrimitiveFunction.free],
      };
  PrimitiveFunction classify(PrimitiveObservation value) {
    final functions = supportedFunctions(value.type);
    final declared = value.measures['classificationCode']?.toInt();
    if (declared != null && declared >= 0 && declared < functions.length) {
      return functions[declared];
    }
    return switch (value.type) {
      PrimitiveType.plane => _plane(value),
      PrimitiveType.cylinder => _cylinder(value),
      PrimitiveType.cone =>
        (value.measures['angleDegrees'] ?? 90) <= policy.draftMaximumDegrees
            ? PrimitiveFunction.draft
            : PrimitiveFunction.seat,
      PrimitiveType.sphere =>
        (value.measures['symmetry'] ?? 0) > 0
            ? PrimitiveFunction.joint
            : PrimitiveFunction.reference,
      PrimitiveType.torus => PrimitiveFunction.functionalRadius,
      _ => PrimitiveFunction.free,
    };
  }

  PrimitiveFunction _plane(PrimitiveObservation value) {
    if ((value.measures['area'] ?? 0) >= policy.largeArea) {
      return PrimitiveFunction.support;
    }
    if ((value.measures['symmetry'] ?? 0) > 0) {
      return PrimitiveFunction.symmetry;
    }
    return PrimitiveFunction.reference;
  }

  PrimitiveFunction _cylinder(PrimitiveObservation value) {
    final radius = value.measures['radius'] ?? 0;
    final length = value.measures['length'] ?? 0;
    if (radius > 0 && length / radius >= policy.deepCylinderRatio) {
      return PrimitiveFunction.hole;
    }
    if ((value.measures['coaxiality'] ?? 0) > 0) {
      return PrimitiveFunction.mainAxis;
    }
    return PrimitiveFunction.revolution;
  }
}
