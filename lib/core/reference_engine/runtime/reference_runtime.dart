import '../../engineering/runtime/engineering_runtime.dart';

import '../../smart_regions/models/geometry.dart';
import '../analytics/reference_analytics_engine.dart';
import '../models/reference_entity.dart';
import '../models/reference_geometry.dart';

abstract interface class ReferenceComputeRuntime {
  Future<ReferenceAnalytics> analyze(
    ReferenceGeometry geometry,
    List<Vec3> samples,
  );
}

class IsolateReferenceRuntime implements ReferenceComputeRuntime {
  const IsolateReferenceRuntime();
  @override
  Future<ReferenceAnalytics> analyze(
    ReferenceGeometry geometry,
    List<Vec3> samples,
  ) => EngineeringRuntime.shared
      .submit(
        'reference:${DateTime.now().microsecondsSinceEpoch}',
        () => const ReferenceAnalyticsEngine().evaluate(geometry, samples),
        namespace: 'reference',
      )
      .future;
}
