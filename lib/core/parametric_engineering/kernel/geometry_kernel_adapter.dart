import '../features/engineering_feature.dart';
import '../solids/engineering_solid.dart';

enum BooleanOperation { union, subtract, intersect }

class KernelCapabilities {
  const KernelCapabilities({
    this.features = const {},
    this.booleans = false,
    this.validation = false,
  });
  final Set<FeatureKind> features;
  final bool booleans, validation;
}

abstract interface class GeometryKernelAdapter {
  String get id;
  KernelCapabilities get capabilities;
  Future<SolidHandle> executeFeature(
    EngineeringFeature feature,
    List<SolidHandle> inputs,
  );
  Future<SolidHandle> boolean(
    BooleanOperation operation,
    List<SolidHandle> inputs,
  );
  Future<List<String>> validate(SolidHandle solid);
}

class UnavailableGeometryKernel implements GeometryKernelAdapter {
  const UnavailableGeometryKernel();
  @override
  String get id => 'unavailable';
  @override
  KernelCapabilities get capabilities => const KernelCapabilities();
  @override
  Future<SolidHandle> executeFeature(
    EngineeringFeature feature,
    List<SolidHandle> inputs,
  ) => throw UnsupportedError(
    'Install a GeometryKernelAdapter to execute ${feature.kind.name}',
  );
  @override
  Future<SolidHandle> boolean(
    BooleanOperation operation,
    List<SolidHandle> inputs,
  ) => throw UnsupportedError(
    'Real geometric booleans require a GeometryKernelAdapter',
  );
  @override
  Future<List<String>> validate(SolidHandle solid) => throw UnsupportedError(
    'Solid validation requires a GeometryKernelAdapter',
  );
}
