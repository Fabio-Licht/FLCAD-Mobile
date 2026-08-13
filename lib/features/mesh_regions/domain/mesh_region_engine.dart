import '../../../core/smart_regions/api/smart_regions_api.dart';
import '../../../core/smart_regions/models/geometry.dart';
import '../../../core/smart_regions/models/smart_region.dart';
import '../../../core/smart_regions/selection/triangle_selection.dart';

/// Feature-level facade kept for compatibility. The proprietary implementation
/// lives in core/smart_regions and is shared by Mobile, Desktop and Cloud.
class MeshRegionEngine {
  MeshRegionEngine({SmartRegionsApi? api}) : _api = api ?? SmartRegionsApi();
  final SmartRegionsApi _api;

  Future<SmartRegion> create({
    required String projectId,
    required MeshTopology mesh,
    required TriangleSelection selection,
    required String name,
  }) => _api.create(
    projectId: projectId,
    mesh: mesh,
    selection: selection,
    name: name,
  );
}
