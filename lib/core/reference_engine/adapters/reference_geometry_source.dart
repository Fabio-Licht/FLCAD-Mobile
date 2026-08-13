import '../../smart_regions/models/geometry.dart';

abstract interface class ReferenceGeometrySource {
  String get id;
  String get fingerprint;
  Future<List<Vec3>> samplePoints();
}

abstract interface class ReferenceEntityConsumer {
  Future<void> accept(String projectId, String referenceId);
}
