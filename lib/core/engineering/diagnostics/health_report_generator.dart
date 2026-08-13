import '../cache/engineering_cache.dart';
import '../runtime/engineering_runtime.dart';
import '../serialization/schema_registry.dart';
import '../services/engineering_service_registry.dart';

class EngineeringHealthSnapshot {
  const EngineeringHealthSnapshot({
    required this.generatedAt,
    required this.runtime,
    required this.cache,
    required this.schemas,
    required this.registeredServices,
  });
  final DateTime generatedAt;
  final EngineeringRuntimeMetrics runtime;
  final EngineeringCacheStatistics cache;
  final int schemas, registeredServices;
}

class EngineeringHealthReportGenerator {
  const EngineeringHealthReportGenerator();
  EngineeringHealthSnapshot capture({
    required EngineeringRuntime runtime,
    required EngineeringCache cache,
    required SchemaRegistry schemas,
    required EngineeringServiceRegistry services,
  }) => EngineeringHealthSnapshot(
    generatedAt: DateTime.now(),
    runtime: runtime.metrics,
    cache: cache.statistics,
    schemas: schemas.schemas.length,
    registeredServices: services.types.length,
  );

  String markdown(EngineeringHealthSnapshot value) =>
      '''# Engineering Health

Generated: ${value.generatedAt.toUtc().toIso8601String()}

- Runtime: ${value.runtime.running} running, ${value.runtime.queued} queued, ${value.runtime.failed} failed
- Cache: ${value.cache.entries} entries, ${(value.cache.hitRate * 100).toStringAsFixed(2)}% hit rate
- Schemas: ${value.schemas}
- Registered services: ${value.registeredServices}
''';
}
