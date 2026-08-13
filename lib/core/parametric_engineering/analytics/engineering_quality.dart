import '../features/engineering_feature.dart';
import '../solids/engineering_solid.dart';

class EngineeringQuality {
  const EngineeringQuality(
    this.featureQuality,
    this.solidQuality,
    this.manufacturingQuality,
    this.inspectionQuality,
    this.total,
  );
  final double featureQuality,
      solidQuality,
      manufacturingQuality,
      inspectionQuality,
      total;
}

class EngineeringQualityEngine {
  const EngineeringQualityEngine();
  EngineeringQuality evaluate(
    List<EngineeringFeature> features,
    List<EngineeringSolid> solids,
  ) {
    final fq = features.isEmpty
            ? 0.0
            : features.where((f) => f.status != FeatureStatus.invalid).length /
                  features.length,
        sq = solids.isEmpty
            ? 0.5
            : solids.where((s) => s.handle != null).length / solids.length,
        mq = features.isEmpty
            ? 0.0
            : features
                      .where(
                        (f) => f.manufacturing != ManufacturingStrategy.unknown,
                      )
                      .length /
                  features.length,
        iq = features.isEmpty
            ? 0.0
            : features
                      .where((f) => f.inspection != InspectionStrategy.unknown)
                      .length /
                  features.length;
    return EngineeringQuality(
      fq,
      sq,
      mq,
      iq,
      (fq * .35 + sq * .25 + mq * .2 + iq * .2).clamp(0, 1).toDouble(),
    );
  }
}
