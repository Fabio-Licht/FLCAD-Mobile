import '../models/surface_topology_models.dart';

class SurfaceTopologyAdvisor {
  const SurfaceTopologyAdvisor();
  List<TopologyAdvice> advise(
    List<PatchEntity> patches,
    List<BoundaryEntity> boundaries,
    List<LoopEntity> loops,
  ) => [
    for (final b in boundaries.where((e) => e.type == BoundaryType.open))
      TopologyAdvice(
        b.id,
        'Estender superfície',
        'Boundary aberta detectada; nenhuma extensão foi executada.',
      ),
    for (final l in loops.where((e) => e.health == TopologyHealth.invalid))
      TopologyAdvice(
        l.id,
        'Recalcular limites',
        'Loop inválido detectado; nenhuma correção foi aplicada.',
      ),
    for (final p in patches.where((e) => e.adjacentPatchIds.isEmpty))
      TopologyAdvice(
        p.id,
        'Verificar reconhecimento',
        'Patch isolado; recomendação exclusivamente consultiva.',
      ),
  ];
}
