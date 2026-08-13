import '../features/engineering_feature.dart';
import '../solids/engineering_solid.dart';

class ValidationReport {
  const ValidationReport(this.valid, this.issues, this.suggestions);
  final bool valid;
  final List<String> issues, suggestions;
}

class FeatureValidator {
  const FeatureValidator();
  ValidationReport validate(EngineeringFeature f) {
    final issues = <String>[];
    if (f.sourceIds.isEmpty) issues.add('Feature requires a source');
    if (f.kind == FeatureKind.extrude &&
        (f.parameters['distance'] as num? ?? 0) <= 0) {
      issues.add('Extrude distance must be positive');
    }
    return ValidationReport(issues.isEmpty, issues, [
      if (issues.isNotEmpty) 'Review feature parameters and sources',
    ]);
  }
}

class ManufacturingValidator {
  const ManufacturingValidator();
  ValidationReport validate(EngineeringFeature f) {
    final issues = <String>[];
    final thickness = (f.parameters['thickness'] as num?)?.toDouble();
    if (thickness != null && thickness <= 0) {
      issues.add('Invalid wall thickness');
    }
    return ValidationReport(issues.isEmpty, issues, [
      if (issues.isNotEmpty) 'Increase minimum manufacturable thickness',
    ]);
  }
}

class SolidValidator {
  const SolidValidator();
  ValidationReport validate(EngineeringSolid s) => ValidationReport(
    s.handle != null,
    s.handle == null ? const ['Solid has no kernel result'] : const [],
    s.handle == null
        ? const ['Install and execute a GeometryKernelAdapter']
        : const [],
  );
}
