import '../../smart_regions/models/geometry.dart';
import '../../smart_regions/models/smart_region.dart';
import '../types/fel_type.dart';

typedef FELFunction = FELValue Function(List<FELValue> arguments);

class FELFunctionLibrary {
  final Map<String, FELFunction> _functions = {};
  FELFunctionLibrary() {
    register(
      'AREA',
      (a) => FELValue(
        FELType.number,
        (a.first.value as SmartRegion).statistics.area,
      ),
    );
    register(
      'PERIMETER',
      (a) => FELValue(
        FELType.number,
        (a.first.value as SmartRegion).statistics.perimeter,
      ),
    );
    register(
      'CURVATURE',
      (a) => FELValue(
        FELType.number,
        (a.first.value as SmartRegion).statistics.averageCurvature,
      ),
    );
    register(
      'NORMAL',
      (a) => FELValue(
        FELType.vector,
        (a.first.value as SmartRegion).statistics.averageNormal,
      ),
    );
    register(
      'CENTER',
      (a) => FELValue(
        FELType.point,
        (a.first.value as SmartRegion).statistics.centroid,
      ),
    );
    register('DISTANCE', (a) {
      final p = a[0].value as Vec3, q = a[1].value as Vec3;
      return FELValue(FELType.number, (p - q).length);
    });
    register(
      'LENGTH',
      (a) => FELValue(FELType.number, (a.first.value as Vec3).length),
    );
    register(
      'RADIUS',
      (a) => FELValue(FELType.number, ((a.first.value as num) / 2)),
    );
    register(
      'DIAMETER',
      (a) => FELValue(FELType.number, ((a.first.value as num) * 2)),
    );
  }
  void register(String name, FELFunction function) =>
      _functions[name.toUpperCase()] = function;
  FELFunction? find(String name) => _functions[name.toUpperCase()];
  Set<String> get names => Set.unmodifiable(_functions.keys);
}
