import '../models/sketch.dart';

class SketchCache {
  final Map<String, IntelligentSketch> _values = {};
  IntelligentSketch? read(String dna) => _values[dna];
  void write(String dna, IntelligentSketch sketch) => _values[dna] = sketch;
  void invalidate(String dna) => _values.remove(dna);
  void clear() => _values.clear();
}
