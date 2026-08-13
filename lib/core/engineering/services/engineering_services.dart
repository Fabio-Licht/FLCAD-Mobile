import '../benchmark/engineering_benchmark.dart';
import '../configuration/engineering_configuration.dart';
import '../diagnostics/engineering_diagnostics.dart';
import '../logging/engineering_logger.dart';
import '../metrics/engineering_metrics.dart';

abstract interface class EngineeringProfiler {
  Future<T> profile<T>(String operation, Future<T> Function() callback);
}

abstract interface class EngineeringFeatureFlags {
  bool enabled(String flag);
}

abstract interface class EngineeringLicensingContract {
  Future<bool> allows(String capability);
}

abstract interface class EngineeringCloudContract {
  Future<bool> get available;
}

class EngineeringServices {
  EngineeringServices({
    required this.logger,
    required this.metrics,
    required this.diagnostics,
    required this.benchmark,
    required this.configuration,
    required this.profiler,
    required this.featureFlags,
    required this.licensing,
    required this.cloud,
  });
  final EngineeringLogger logger;
  final EngineeringMetrics metrics;
  final EngineeringDiagnostics diagnostics;
  final EngineeringBenchmark benchmark;
  final EngineeringConfiguration configuration;
  final EngineeringProfiler profiler;
  final EngineeringFeatureFlags featureFlags;
  final EngineeringLicensingContract licensing;
  final EngineeringCloudContract cloud;
}
