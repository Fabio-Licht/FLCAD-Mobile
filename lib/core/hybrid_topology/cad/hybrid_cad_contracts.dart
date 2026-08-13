import '../hybrid/hybrid_object.dart';

abstract interface class CADTopologyAdapter {
  Future<GeometryAssetRef> importSurface(String projectId, String source);
  Future<void> synchronize(GeometryAssetRef mesh, GeometryAssetRef cad);
}

abstract interface class SolidTopologyContract {
  String get id;
  Future<void> invalidate(Set<String> sourceIds);
}
