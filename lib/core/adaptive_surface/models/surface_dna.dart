import 'adaptive_surface.dart';
import 'surface_geometry.dart';

SurfaceDNA createSurfaceDNA(
  List<String> sources,
  SurfaceGeometry geometry,
  String intent,
) {
  final source = sources.join('|'),
      signature = geometry.toJson().toString(),
      raw = '$source::$signature::$intent',
      hash = raw.codeUnits
          .fold<int>(17, (a, b) => 37 * a + b)
          .toUnsigned(32)
          .toRadixString(16);
  return SurfaceDNA(source, signature, intent, hash);
}
