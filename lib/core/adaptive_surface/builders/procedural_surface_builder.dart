import '../models/surface_geometry.dart';
import 'primitive_surface_builders.dart';
import 'surface_builder.dart';

class ProceduralSurfaceBuilder implements SurfaceBuilder {
  @override
  String get id => 'procedural-surface';
  @override
  Set<SurfaceKind> get supportedKinds => const {
    SurfaceKind.cylinder,
    SurfaceKind.cone,
    SurfaceKind.torus,
    SurfaceKind.sweep,
    SurfaceKind.loft,
    SurfaceKind.extrusion,
    SurfaceKind.revolution,
    SurfaceKind.offset,
    SurfaceKind.blend,
    SurfaceKind.bridge,
  };
  @override
  Future<SurfaceCandidate> build(SurfaceBuildRequest request) async {
    final kind = request.targetKind;
    if (kind == null || !supportedKinds.contains(kind)) {
      throw ArgumentError('Explicit procedural surface kind required');
    }
    if (request.samples.length < 2) {
      throw ArgumentError('Guide or profile required');
    }
    return SurfaceCandidate(
      solverId: id,
      geometry: ParametricSurfaceGeometry(
        kind,
        request.parameters.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
        controlPoints: request.samples,
        degreeU: 3,
        degreeV: 3,
      ),
      metrics: metrics(const [], request.samples.length, continuity: .7),
      complexity: .5,
      metadata: const {'requiresDownstreamKernel': true},
    );
  }
}
