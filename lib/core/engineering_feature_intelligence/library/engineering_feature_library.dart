import '../../primitive_intelligence/models/primitive_intelligence_models.dart';
import '../models/engineering_feature_models.dart';

class EngineeringFeatureLibrary {
  const EngineeringFeatureLibrary();
  List<EngineeringFeatureType> candidates(PrimitiveHypothesis primitive) {
    final declared = primitive.primitive.measures['featureCode']?.toInt();
    if (declared != null &&
        declared >= 0 &&
        declared < EngineeringFeatureType.values.length) {
      return [EngineeringFeatureType.values[declared]];
    }
    return switch (primitive.function) {
      PrimitiveFunction.hole => const [
        EngineeringFeatureType.simpleHole,
        EngineeringFeatureType.throughHole,
        EngineeringFeatureType.blindHole,
        EngineeringFeatureType.steppedHole,
        EngineeringFeatureType.countersunkHole,
        EngineeringFeatureType.threadedHole,
      ],
      PrimitiveFunction.support => const [
        EngineeringFeatureType.datumFeature,
        EngineeringFeatureType.extrusion,
      ],
      PrimitiveFunction.mainAxis || PrimitiveFunction.revolution => const [
        EngineeringFeatureType.shaft,
        EngineeringFeatureType.revolution,
        EngineeringFeatureType.bearingSeat,
      ],
      PrimitiveFunction.draft => const [
        EngineeringFeatureType.draftRegion,
        EngineeringFeatureType.moldPartingCandidate,
      ],
      PrimitiveFunction.functionalRadius => const [
        EngineeringFeatureType.fillet,
        EngineeringFeatureType.blendRegion,
      ],
      PrimitiveFunction.joint => const [EngineeringFeatureType.housing],
      _ => const [EngineeringFeatureType.machiningFeature],
    };
  }

  EngineeringFeatureType select(PrimitiveHypothesis primitive) =>
      candidates(primitive).first;
  FeatureFunction function(EngineeringFeatureType type, {int? declaredCode}) {
    if (declaredCode != null &&
        declaredCode >= 0 &&
        declaredCode < FeatureFunction.values.length) {
      return FeatureFunction.values[declaredCode];
    }
    return switch (type) {
      EngineeringFeatureType.bearingSeat ||
      EngineeringFeatureType.flange ||
      EngineeringFeatureType.housing ||
      EngineeringFeatureType.shaft ||
      EngineeringFeatureType.keyway => FeatureFunction.assembly,
      EngineeringFeatureType.rib ||
      EngineeringFeatureType.cylindricalBoss ||
      EngineeringFeatureType.prismaticBoss => FeatureFunction.structural,
      EngineeringFeatureType.datumFeature => FeatureFunction.reference,
      EngineeringFeatureType.machiningFeature ||
      EngineeringFeatureType.draftRegion ||
      EngineeringFeatureType.moldPartingCandidate ||
      EngineeringFeatureType.stampingRegion ||
      EngineeringFeatureType.electrodeCandidate =>
        FeatureFunction.manufacturing,
      _ => FeatureFunction.functional,
    };
  }
}
