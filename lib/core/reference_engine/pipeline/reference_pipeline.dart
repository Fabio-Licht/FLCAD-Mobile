import '../../smart_regions/models/geometry.dart';
import '../../smart_regions/models/smart_region.dart';
import '../api/reference_api.dart';
import '../models/reference_entity.dart';

class ReferencePipelineStep {
  const ReferencePipelineStep(this.name, this.mode, this.recipe);
  final String name;
  final ReferenceMode mode;
  final ReferenceRecipe recipe;
}

class ReferencePipeline {
  ReferencePipeline(this.api);
  final ReferenceApi api;

  Future<List<ReferenceEntity>> execute(
    String projectId,
    List<ReferencePipelineStep> steps, {
    Map<String, MeshTopology> meshes = const {},
    Map<String, SmartRegion> regions = const {},
  }) async {
    final output = <ReferenceEntity>[];
    for (final step in steps) {
      final sources = step.recipe.sourceIds
          .map((id) => id == r'$previous' ? output.last.id : id)
          .toList();
      output.add(
        await api.create(
          projectId: projectId,
          name: step.name,
          mode: step.mode,
          recipe: ReferenceRecipe(
            step.recipe.builderId,
            step.recipe.parameters,
            sources,
          ),
          meshes: meshes,
          regions: regions,
        ),
      );
    }
    return output;
  }
}
