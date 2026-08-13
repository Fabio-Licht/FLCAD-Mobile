import '../builders/reference_builder.dart';

class ReferenceCache {
  final Map<String, ReferenceBuildResult> _values = {};
  ReferenceBuildResult? read(String builder, String fingerprint) =>
      _values['$builder:$fingerprint'];
  void write(String builder, String fingerprint, ReferenceBuildResult result) =>
      _values['$builder:$fingerprint'] = result;
  void invalidate(String fingerprint) =>
      _values.removeWhere((key, _) => key.endsWith(':$fingerprint'));
}
