import '../continuity/surface_continuity.dart';
import '../models/adaptive_surface.dart';

class SurfaceNetwork {
  SurfaceNetwork({this.surfaces = const {}, this.constraints = const []});
  final Map<String, AdaptiveSurface> surfaces;
  final List<SurfaceContinuityConstraint> constraints;
  SurfaceNetwork add(AdaptiveSurface s) => SurfaceNetwork(
    surfaces: {...surfaces, s.id: s},
    constraints: constraints,
  );
  SurfaceNetwork connect(String a, String b, SurfaceContinuityLevel level) {
    if (!surfaces.containsKey(a) || !surfaces.containsKey(b)) {
      throw StateError('Surface missing');
    }
    return SurfaceNetwork(
      surfaces: surfaces,
      constraints: [
        ...constraints,
        SurfaceContinuityConstraint(
          id: '$a:$b:${level.name}',
          surfaceIds: [a, b],
          level: level,
        ),
      ],
    );
  }

  List<AdaptiveSurface> neighbors(String id) => constraints
      .where((c) => c.surfaceIds.contains(id))
      .expand((c) => c.surfaceIds)
      .where((v) => v != id)
      .toSet()
      .map((v) => surfaces[v]!)
      .toList();
}
