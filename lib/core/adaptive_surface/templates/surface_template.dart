import '../models/surface_geometry.dart';

class SurfaceTemplate {
  const SurfaceTemplate(
    this.id,
    this.name,
    this.kind,
    this.parameters, {
    this.corporate = false,
  });
  final String id, name;
  final SurfaceKind kind;
  final Map<String, dynamic> parameters;
  final bool corporate;
}

abstract interface class SurfaceLibrary {
  Future<void> save(SurfaceTemplate template);
  Future<List<SurfaceTemplate>> list();
}

class InMemorySurfaceLibrary implements SurfaceLibrary {
  final Map<String, SurfaceTemplate> _values = {};
  @override
  Future<void> save(SurfaceTemplate value) async => _values[value.id] = value;
  @override
  Future<List<SurfaceTemplate>> list() async =>
      List.unmodifiable(_values.values);
}
