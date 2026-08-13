import '../models/smart_region.dart';

abstract interface class RegionDetector {
  Future<List<SmartRegion>> detect(String projectId, String meshId);
}

abstract interface class RegionClassifier {
  Future<String> classify(SmartRegion region);
}

abstract interface class RegionAdvisor {
  Future<List<String>> advise(SmartRegion region);
}

abstract interface class RegionOptimizer {
  Future<SmartRegion> optimize(SmartRegion region);
}

abstract interface class RegionPredictor {
  Future<double> match(SmartRegion previous, SmartRegion candidate);
}

abstract interface class CADRegionDerivation {
  Future<String> createPlane(SmartRegion region);
  Future<String> createAxis(SmartRegion region);
  Future<String> createCurve(SmartRegion region);
  Future<String> createSketch(SmartRegion region);
  Future<String> createSurface(SmartRegion region);
}

abstract interface class RegionSyncProvider {
  Future<void> push(String projectId, List<SmartRegion> regions);
  Future<List<SmartRegion>> pull(String projectId);
}
