import '../models/surface_topology_models.dart';

class SurfaceTopologyValidation {
  const SurfaceTopologyValidation();
  List<String> validate(SurfaceTopologyReport report) => [
    if (report.patches.any((e) => e.surface.handle == null))
      'Patch without native surface handle',
    if (report.loops.any((e) => e.boundaryIds.isEmpty))
      'Loop without boundaries',
    if (report.intersections.any((e) => e.edgeCount > 0 && e.handle == null))
      'Native intersection without handle',
    if (report.patches.any((e) => e.surface.handle?.type.name == 'solid'))
      'Solid creation is forbidden',
  ];
}
