import '../models/surface_topology_models.dart';

class SurfaceTopologyWorkspace {
  SurfaceTopologyWorkspace(this.report);
  final SurfaceTopologyReport report;
  String? selectedPatchId;
  void selectPatch(String id) {
    if (!report.patches.any((e) => e.id == id)) {
      throw StateError('Unknown patch: $id');
    }
    selectedPatchId = id;
  }

  PatchEntity? get selected =>
      report.patches.where((e) => e.id == selectedPatchId).firstOrNull;
  Map<String, dynamic> get propertyInspector {
    final p = selected;
    if (p == null) {
      return const {};
    }
    final boundaryLength = report.boundaries
        .where((e) => p.boundaryIds.contains(e.id))
        .fold<double>(0, (s, e) => s + e.length);
    return {
      'Patch ID': p.id,
      'Boundary Count': p.boundaryIds.length,
      'Loop Count': p.loopIds.length,
      'Neighbour Count': p.adjacentPatchIds.length,
      'Intersection Count': p.intersectionIds.length,
      'Topology Health': p.health.name,
      'Boundary Length': boundaryLength,
      'Patch Area': p.surface.area,
      'Surface Links': [p.surface.id],
    };
  }

  List<String> get panels => const [
    'Surface Tree',
    'Patch Tree',
    'Boundary Inspector',
    'Loop Inspector',
    'Topology Graph',
    'Intersection Viewer',
    'Topology Analytics',
    'Topology Advisor',
  ];
}
