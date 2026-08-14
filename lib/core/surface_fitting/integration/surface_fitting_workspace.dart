import '../models/surface_fitting_models.dart';

class SurfaceTreeItem {
  SurfaceTreeItem(this.surface);
  final SurfaceEntity surface;
  bool selected = false, highlighted = false;
  Map<String, dynamic> toJson() => {
    ...surface.toJson(),
    'selected': selected,
    'highlighted': highlighted,
  };
}

class SurfaceFittingWorkspace {
  SurfaceFittingWorkspace(SurfaceFittingReport report)
    : items = report.surfaces.map(SurfaceTreeItem.new).toList(),
      analytics = report.analytics.toJson(),
      advisor = report.advice.map((e) => e.toJson()).toList(),
      timeline = [
        {'event': 'Surface fitting completed', 'reportId': report.id},
      ];
  final List<SurfaceTreeItem> items;
  final Map<String, dynamic> analytics;
  final List<Map<String, dynamic>> advisor, timeline;
  String? selectedId;
  void select(String id) {
    var found = false;
    for (final item in items) {
      item.selected = item.surface.id == id;
      item.highlighted = item.selected;
      found |= item.selected;
    }
    if (!found) throw StateError('Unknown surface: $id');
    selectedId = id;
  }

  SurfaceEntity? get selected =>
      items.where((e) => e.selected).firstOrNull?.surface;
  Map<String, dynamic> get propertyInspector {
    final s = selected;
    if (s == null) return const {};
    return {
      'Surface Type': s.primitiveType.name,
      'Radius': s.parameters['radius'] ?? s.parameters['majorRadius'],
      'Axis': s.parameters['axisDirection'],
      'Origin':
          s.parameters['origin'] ??
          s.parameters['axisOrigin'] ??
          s.parameters['center'],
      'Direction': s.parameters['normal'] ?? s.parameters['axisDirection'],
      'Residual RMS': s.residuals.rms,
      'Residual Max': s.residuals.maximum,
      'Residual Mean': s.residuals.mean,
      'Confidence': s.confidence,
      'Health': s.health.name,
      'Recognition Region': s.recognitionRegionId,
    };
  }

  Map<String, dynamic> get tree => {
    'Surface Reconstruction': {
      'Planes': _type('plane'),
      'Cylinders': _type('cylinder'),
      'Cones': _type('cone'),
      'Spheres': _type('sphere'),
      'Tori': _type('torus'),
      'Failed Fits': items
          .where((e) => e.surface.status != SurfaceFitStatus.accepted)
          .map((e) => e.toJson())
          .toList(),
    },
  };
  List<Map<String, dynamic>> _type(String type) => items
      .where(
        (e) =>
            e.surface.primitiveType.name == type &&
            e.surface.status == SurfaceFitStatus.accepted,
      )
      .map((e) => e.toJson())
      .toList();
}
