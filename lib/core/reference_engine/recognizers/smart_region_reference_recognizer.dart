import '../../smart_regions/models/smart_region.dart';
import '../models/reference_entity.dart';
import '../services/integration_contracts.dart';

class SmartRegionReferenceRecognizer implements ReferenceRecognizer {
  const SmartRegionReferenceRecognizer(this.regions);
  final Map<String, SmartRegion> regions;

  @override
  Future<List<ReferenceRecipe>> recognize(
    String projectId,
    String sourceId,
  ) async {
    final region = regions[sourceId];
    if (region == null || region.projectId != projectId) return const [];
    final recipes = <ReferenceRecipe>[];
    if (region.statistics.dominantType.toLowerCase() == 'plane' ||
        region.statistics.averageCurvature.abs() <= 1e-3) {
      recipes.add(
        ReferenceRecipe('plane', const {'method': 'bestFit'}, [sourceId]),
      );
    }
    recipes.add(
      ReferenceRecipe('point', const {'method': 'centroid'}, [sourceId]),
    );
    return recipes;
  }
}
