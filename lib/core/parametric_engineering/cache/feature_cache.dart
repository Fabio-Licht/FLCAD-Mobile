import '../solids/engineering_solid.dart';

class FeatureCache {
  final Map<String, SolidHandle> _values = {};
  SolidHandle? read(String dna) => _values[dna];
  void write(String dna, SolidHandle value) => _values[dna] = value;
  void invalidate(String dna) => _values.remove(dna);
}
