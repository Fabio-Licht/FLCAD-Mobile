import '../../engineering/services/engineering_service_registry.dart';
import '../computational_geometry/geometry_algorithms.dart';
import '../linear_algebra/linear_algebra.dart';
import '../precision/precision.dart';
import '../runtime/geometric_kernel_runtime.dart';
import '../services/fitting_engine.dart';
import '../validation/geometry_validation.dart';

class GeometricKernelApi {
  const GeometricKernelApi({
    this.precision = const PrecisionContext(),
    this.geometry = const GeometryAlgorithms(),
    this.linearAlgebra = const LinearAlgebra(),
    this.fitting = const FittingEngine(),
  });
  final PrecisionContext precision;
  final GeometryAlgorithms geometry;
  final LinearAlgebra linearAlgebra;
  final FittingEngine fitting;
  GeometryValidator get validator => GeometryValidator(precision);
  GeometricKernelRuntime runtime({KernelMetricsSink? metrics}) =>
      GeometricKernelRuntime(precision: precision, metricsSink: metrics);
  void install(EngineeringServiceRegistry services) =>
      services.register<GeometricKernelApi>(this);
}
