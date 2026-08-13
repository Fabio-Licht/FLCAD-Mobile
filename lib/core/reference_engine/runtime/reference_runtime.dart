import 'dart:isolate';

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
  ) => Isolate.run(
    () => const ReferenceAnalyticsEngine().evaluate(geometry, samples),
  );
}
