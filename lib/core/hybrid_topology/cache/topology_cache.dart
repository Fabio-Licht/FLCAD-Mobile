import '../morphing/mesh_morph_engine.dart';

class TopologyCache {
  final Map<String, MorphResult> _values = {};
  MorphResult? read(String key) => _values[key];
  void write(String key, MorphResult value) => _values[key] = value;
  void clear() => _values.clear();
}
