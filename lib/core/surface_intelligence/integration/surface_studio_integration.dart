import '../../engineering_studio/models/studio_models.dart';
import '../../engineering_studio/tree/engineering_tree_manager.dart';
import '../models/surface_models.dart';

class SurfaceStudioIntegration {
  const SurfaceStudioIntegration();
  EngineeringTreeNode root(SurfacePlan plan) => EngineeringTreeNode(
    id: '${plan.id}-root',
    projectId: plan.projectId,
    name: 'Surface Plan',
    type: StudioEntityType.surfacePlan,
    status: plan.valid ? 'valid' : 'attention',
  );
  EngineeringTreeNode candidate(
    SurfacePlan plan,
    SurfaceCandidate value,
    String rootId,
  ) => EngineeringTreeNode(
    id: value.id,
    projectId: plan.projectId,
    name:
        '${value.kind.name} ${(plan.candidates.indexOf(value) + 1).toString().padLeft(2, '0')}',
    type: StudioEntityType.surfaceCandidate,
    parentId: rootId,
    status: 'planned',
    confidence: value.confidence,
    context: {
      'strategy': plan.strategies
          .where((e) => e.candidateId == value.id)
          .firstOrNull
          ?.toJson(),
      'predictedContinuity': value.predictedContinuity.name,
      'justification': value.justification,
      'regions': value.regionIds,
      'alternatives': plan.candidates
          .where(
            (e) =>
                e.id != value.id && e.regionIds.any(value.regionIds.contains),
          )
          .map((e) => e.kind.name)
          .toList(),
      'surfaceScore': plan.strategies
          .where((e) => e.candidateId == value.id)
          .firstOrNull
          ?.score,
      'valid': plan.valid,
    },
  );
  void populate(EngineeringTreeManager tree, SurfacePlan plan) {
    final parent = root(plan);
    tree.add(parent);
    for (final value in plan.candidates) {
      tree.add(candidate(plan, value, parent.id));
    }
    tree.add(
      EngineeringTreeNode(
        id: '${plan.id}-remaining',
        projectId: plan.projectId,
        name: 'Remaining Regions',
        type: StudioEntityType.surfaceCandidate,
        parentId: parent.id,
        status: plan.boundaryReport.openEdges == 0 ? 'resolved' : 'attention',
        context: {'openEdges': plan.boundaryReport.openEdges},
      ),
    );
  }
}
