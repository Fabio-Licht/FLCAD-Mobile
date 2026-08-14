import '../models/surface_continuity_models.dart';

class SurfaceQualityWorkspace {
  SurfaceQualityWorkspace(this.report);
  final SurfaceQualityReport report;
  String? selectedPatchId;
  void select(String id) {
    if (!report.patchQualities.any((e) => e.patch.id == id)) {
      throw StateError('Unknown quality patch: $id');
    }
    selectedPatchId = id;
  }

  PatchQuality? get selected => report.patchQualities
      .where((e) => e.patch.id == selectedPatchId)
      .firstOrNull;
  Map<String, dynamic> get propertyInspector {
    final q = selected;
    if (q == null) return const {};
    return {
      'Continuity': q.continuityScore,
      'Curvature': q.curvature.toJson(),
      'Reflection': q.reflection.toJson(),
      'Draft': q.draft.toJson(),
      'Surface Health': q.health.name,
      'Neighbour Count': q.patch.adjacentPatchIds.length,
      'Quality Score': q.overall,
    };
  }

  List<String> get panels => const [
    'Continuity Tree',
    'Surface Quality',
    'Curvature Inspector',
    'Reflection Inspector',
    'Zebra Analysis',
    'Draft Analysis',
    'Quality Timeline',
    'Quality Analytics',
    'Quality Advisor',
  ];
}
