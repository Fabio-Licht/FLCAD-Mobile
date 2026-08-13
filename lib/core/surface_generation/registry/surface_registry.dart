import '../models/surface_generation_models.dart';

class SurfaceRegistry {
  final Map<String, GeneratedSurface> _surfaces = {};
  List<GeneratedSurface> get surfaces => List.unmodifiable(_surfaces.values);
  void register(GeneratedSurface surface) {
    if (_surfaces.containsKey(surface.surfaceId)) {
      throw StateError('Surface ${surface.surfaceId} already registered');
    }
    _surfaces[surface.surfaceId] = surface;
  }

  GeneratedSurface? find(String id) => _surfaces[id];
  GeneratedSurface? remove(String id) => _surfaces.remove(id);
}
