import '../models/revolve_models.dart';
import 'revolve_validation.dart';

class RevolveQuality {
  const RevolveQuality(
    this.overall,
    this.axis,
    this.parameters,
    this.manufacturability,
    this.rebuildStability,
    this.dependency,
  );
  final int overall,
      axis,
      parameters,
      manufacturability,
      rebuildStability,
      dependency;
}

class RevolveQualityEvaluator {
  const RevolveQualityEvaluator();
  RevolveQuality evaluate(RevolveFeature f, RevolveValidationResult v) {
    final axis = (100 -
        v.issues.where(
              (i) =>
                  i.type == RevolveValidationIssueType.missingAxis ||
                  i.type == RevolveValidationIssueType.invalidAxis,
            ).length *
            40).clamp(0, 100), parameters = (100 -
        v.issues.where(
              (i) =>
                  i.type == RevolveValidationIssueType.invalidAngle ||
                  i.type == RevolveValidationIssueType.zeroAngle ||
                  i.type == RevolveValidationIssueType.angleOver360,
            ).length *
            25).clamp(0, 100), manufacturing = (100 -
        (f.parameters.type == RevolveType.thin && f.parameters.thickness <= 0 ? 30 : 0)).clamp(0, 100), stability = f.status == RevolveStatus.failed ? 50 : 100, dependency = (100 - f.dependencies.where((d) => d.isEmpty).length * 10).clamp(0, 100), overall = ((axis + parameters + manufacturing + stability + dependency) / 5).round();
    return RevolveQuality(
      overall,
      axis,
      parameters,
      manufacturing,
      stability,
      dependency,
    );
  }
}
