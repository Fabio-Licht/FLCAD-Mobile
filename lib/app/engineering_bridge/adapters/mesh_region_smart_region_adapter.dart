import '../../../core/smart_regions/api/smart_regions_api.dart';
import '../../../core/smart_regions/models/geometry.dart';
import '../../../core/smart_regions/models/smart_region.dart';
import '../../../core/smart_regions/selection/triangle_selection.dart';
import '../contracts/bridge_context.dart';
import '../contracts/bridge_selection.dart';
import '../contracts/bridge_validation.dart';

class SmartRegionAdaptation {
  const SmartRegionAdaptation(this.region, this.mesh);
  final SmartRegion region;
  final MeshTopology mesh;
}

class MeshRegionSmartRegionAdapter {
  const MeshRegionSmartRegionAdapter(
    this.api, {
    this.validation = const BridgeValidation(),
  });
  final SmartRegionsApi api;
  final BridgeValidation validation;
  Future<SmartRegionAdaptation> adapt({
    required BridgeContext context,
    required BridgeSelection selection,
    required String name,
  }) async {
    validation.requireRegion(context);
    final geometry = selection.geometry;
    final vertices = <Vec3>[
      for (var index = 0; index + 2 < geometry.nodes.length; index += 3)
        Vec3(
          geometry.nodes[index],
          geometry.nodes[index + 1],
          geometry.nodes[index + 2],
        ),
    ];
    final triangles = <Triangle>[
      for (var index = 0; index + 2 < geometry.triangles.length; index += 3)
        Triangle(
          geometry.triangles[index],
          geometry.triangles[index + 1],
          geometry.triangles[index + 2],
        ),
    ];
    final mesh = MeshTopology(
      id: context.meshId,
      vertices: vertices,
      triangles: triangles,
    );
    final region = await api.create(
      projectId: context.projectId,
      mesh: mesh,
      selection: TriangleSelection(context.region!.triangleIndices),
      name: name,
    );
    if (region.dna.hash.isEmpty ||
        region.statistics.triangleCount !=
            context.region!.triangleIndices.length) {
      throw StateError(
        'Official Smart Region analysis did not preserve the selected mesh region.',
      );
    }
    return SmartRegionAdaptation(region, mesh);
  }
}
