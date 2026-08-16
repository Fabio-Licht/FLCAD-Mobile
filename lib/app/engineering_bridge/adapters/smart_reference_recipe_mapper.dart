import '../../../core/reference_engine/models/reference_entity.dart';
import '../../../core/smart_reference/models/smart_reference_models.dart';
import '../../../core/smart_regions/models/smart_region.dart';

class SmartReferenceRecipeMapper {
  const SmartReferenceRecipeMapper();
  ReferenceRecipe map({
    required ReferenceCandidate candidate,
    required SmartRegion region,
    Map<String, dynamic> approvedParameters = const {},
  }) {
    if (candidate.evidence.isEmpty) {
      throw StateError('Smart Reference candidate requires evidence.');
    }
    return switch (candidate.category) {
      ReferenceCategory.plane => ReferenceRecipe(
        'plane',
        {
          'method': 'region',
          'tolerance': approvedParameters['tolerance'] ?? 0.01,
        },
        [region.id],
      ),
      ReferenceCategory.point => ReferenceRecipe(
        'point',
        {
          'method': 'centroid',
          'tolerance': approvedParameters['tolerance'] ?? 0.01,
        },
        [region.id],
      ),
      ReferenceCategory.axis => _axis(region, approvedParameters),
      ReferenceCategory.coordinateSystem => _coordinateSystem(
        approvedParameters,
      ),
    };
  }

  ReferenceRecipe _axis(SmartRegion region, Map<String, dynamic> values) {
    final origin = _vector(values, 'origin'),
        direction = _vector(values, 'direction');
    final second = [
      origin[0] + direction[0],
      origin[1] + direction[1],
      origin[2] + direction[2],
    ];
    return ReferenceRecipe(
      'axis',
      {
        'method': 'twoPoints',
        'points': [origin, second],
        'tolerance': values['tolerance'] ?? 0.01,
      },
      [region.id],
    );
  }

  ReferenceRecipe _coordinateSystem(Map<String, dynamic> values) =>
      ReferenceRecipe('coordinateSystem', {
        'origin': _vector(values, 'origin'),
        'xAxis': _vector(values, 'xAxis'),
        'yAxis': _vector(values, 'yAxis'),
        'tolerance': values['tolerance'] ?? 0.01,
      }, const []);
  List<double> _vector(Map<String, dynamic> values, String key) {
    final value = values[key];
    if (value is! List || value.length != 3 || !value.every((e) => e is num)) {
      throw StateError(
        'Approved Smart Reference mapping requires vector $key.',
      );
    }
    return value.cast<num>().map((e) => e.toDouble()).toList();
  }
}
