import '../entities/sketch_entity.dart';
import 'sketch.dart';
import 'sketch_context.dart';

SketchDNA createSketchDNA(
  List<SketchGeometryContext> contexts,
  List<SketchEntity> entities,
) {
  final context = contexts
      .map(
        (value) => '${value.kind.name}:${value.sourceId}:${value.fingerprint}',
      )
      .join('|');
  final geometry = entities.map((value) => value.toJson().toString()).join('|');
  final raw = '$context::$geometry';
  final hash = raw.codeUnits
      .fold<int>(17, (value, unit) => 37 * value + unit)
      .toUnsigned(32)
      .toRadixString(16);
  return SketchDNA(context, geometry, hash);
}
