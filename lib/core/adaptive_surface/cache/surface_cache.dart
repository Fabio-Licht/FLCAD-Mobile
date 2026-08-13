import '../solver/adaptive_surface_solver.dart';

class SurfaceCache {
  final Map<String, SurfaceSolverResult> _values = {};
  SurfaceSolverResult? read(String key) => _values[key];
  void write(String key, SurfaceSolverResult value) => _values[key] = value;
  void invalidate(String fingerprint) =>
      _values.removeWhere((key, _) => key.contains(fingerprint));
}
