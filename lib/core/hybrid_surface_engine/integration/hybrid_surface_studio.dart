import '../../engineering_studio/models/studio_models.dart';
import '../../engineering_studio/tree/engineering_tree_manager.dart';
import '../models/hybrid_surface_models.dart';

class HybridSurfaceStudioIntegration {
  const HybridSurfaceStudioIntegration();
  void populate(EngineeringTreeManager tree, HybridSurfacePlan plan) {
    final root = EngineeringTreeNode(
      id: '${plan.id}-network',
      projectId: plan.projectId,
      name: 'Hybrid Surface Network',
      type: StudioEntityType.hybridSurfaceNetwork,
      status: plan.valid ? 'valid' : 'attention',
      context: {
        'strategy': plan.selectedStrategyId,
        'score': plan.strategies.firstOrNull?.score,
      },
    );
    tree.add(root);
    for (final node in plan.nodes) {
      final strategy = plan.strategies
          .where((e) => e.surfaceIds.contains(node.candidate.id))
          .firstOrNull;
      tree.add(
        EngineeringTreeNode(
          id: node.candidate.id,
          projectId: plan.projectId,
          name: node.candidate.kind.name,
          type: StudioEntityType.hybridSurface,
          parentId: root.id,
          status: 'planned',
          confidence: node.candidate.confidence,
          context: {
            'hybridStrategy': plan.selectedStrategyId,
            'predictedContinuity': node.continuity.name,
            'neighbors': node.neighborIds,
            'surfaceScore': strategy?.score,
            'justification': strategy?.explanation,
            'selectedAlternative': plan.selectedStrategyId,
            'discardedAlternatives': plan.strategies
                .where((e) => e.id != plan.selectedStrategyId)
                .map((e) => e.id)
                .toList(),
          },
        ),
      );
    }
    tree.add(
      EngineeringTreeNode(
        id: '${plan.id}-remaining',
        projectId: plan.projectId,
        name: 'Remaining Regions',
        type: StudioEntityType.hybridSurface,
        parentId: root.id,
        status: plan.diagnostics.isEmpty ? 'resolved' : 'attention',
      ),
    );
  }
}
