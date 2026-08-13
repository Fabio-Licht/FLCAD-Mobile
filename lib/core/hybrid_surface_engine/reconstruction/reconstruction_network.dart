import '../models/hybrid_surface_models.dart';

class ReconstructionNetworkBuilder {
  const ReconstructionNetworkBuilder();
  List<ReconstructionSurfaceNode> build(List<SurfaceNetworkNode> nodes) => nodes
      .map(
        (node) => ReconstructionSurfaceNode(
          id: 'reconstruction-${node.candidate.id}',
          candidateId: node.candidate.id,
          builder: '${node.candidate.kind.name}-builder-contract',
          dependencies: node.dependencies,
          continuity: node.continuity,
          validation: 'surface-validation-contract',
          healing: 'healing-proposal-contract',
          shapeGeneration: 'deferred-to-kernel',
        ),
      )
      .toList();
}
