import 'engineering_feature.dart';

FeatureDNA createFeatureDNA({
  required Iterable<String> origins,
  required String intent,
  required Map<String, dynamic> parameters,
  required ManufacturingStrategy manufacturing,
  required InspectionStrategy inspection,
  required Iterable<String> relations,
}) {
  final o = origins.join('|'),
      p = parameters.toString(),
      m = manufacturing.name,
      i = inspection.name,
      r = relations.join('|'),
      raw = '$o::$intent::$p::$m::$i::$r',
      hash = raw.codeUnits
          .fold<int>(17, (a, b) => 37 * a + b)
          .toUnsigned(32)
          .toRadixString(16);
  return FeatureDNA(o, intent, p, m, i, r, hash);
}
