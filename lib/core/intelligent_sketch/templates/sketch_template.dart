import '../constraints/sketch_constraint.dart';
import '../entities/sketch_entity.dart';

class SketchTemplate {
  const SketchTemplate({
    required this.id,
    required this.name,
    required this.entities,
    required this.constraints,
    this.corporate = false,
    this.metadata = const {},
  });
  final String id, name;
  final List<SketchEntity> entities;
  final List<SketchConstraint> constraints;
  final bool corporate;
  final Map<String, dynamic> metadata;
}

abstract interface class SketchLibrary {
  Future<void> save(SketchTemplate template);
  Future<List<SketchTemplate>> list();
  Future<SketchTemplate?> find(String id);
}

class InMemorySketchLibrary implements SketchLibrary {
  final Map<String, SketchTemplate> _values = {};
  @override
  Future<void> save(SketchTemplate value) async => _values[value.id] = value;
  @override
  Future<List<SketchTemplate>> list() async =>
      List.unmodifiable(_values.values);
  @override
  Future<SketchTemplate?> find(String id) async => _values[id];
}
