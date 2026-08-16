// ignore_for_file: curly_braces_in_flow_control_structures

import '../../../core/reference_engine/api/reference_api.dart';
import '../../../core/reference_engine/models/reference_entity.dart';
import '../../../core/smart_reference/models/smart_reference_models.dart';
import '../../../core/smart_regions/models/geometry.dart';
import '../../../core/smart_regions/models/smart_region.dart';
import '../contracts/bridge_context.dart';
import '../contracts/bridge_validation.dart';

class ReferenceBridge {
  const ReferenceBridge(this.api, {this.validation = const BridgeValidation()});
  final ReferenceApi api;
  final BridgeValidation validation;
  Future<ReferenceEntity> createApproved({
    required BridgeContext context,
    required ReferenceCandidate candidate,
    required ReferenceRecipe recipe,
    required String name,
    Map<String, MeshTopology> meshes = const {},
    Map<String, SmartRegion> regions = const {},
  }) {
    validation.requireConfirmation(context);
    if (candidate.evidence.isEmpty)
      throw StateError('Approved Smart Reference has no evidence.');
    final expectedBuilder = switch (candidate.category) {
      ReferenceCategory.plane => 'plane',
      ReferenceCategory.axis => 'axis',
      ReferenceCategory.point => 'point',
      ReferenceCategory.coordinateSystem => 'coordinateSystem',
    };
    if (recipe.builderId != expectedBuilder) {
      throw StateError(
        'Reference recipe ${recipe.builderId} does not match approved ${candidate.category.name} candidate.',
      );
    }
    return api.create(
      projectId: context.projectId,
      name: name,
      mode: ReferenceMode.staticReference,
      recipe: recipe,
      meshes: meshes,
      regions: regions,
    );
  }

  Future<void> undo(ReferenceEntity entity) => api.delete(entity);
  Future<void> redo(ReferenceEntity entity) => api.restore(entity);
}
