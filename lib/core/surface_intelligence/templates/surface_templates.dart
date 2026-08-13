import '../../adaptive_surface/models/surface_geometry.dart';

class SurfaceTemplate {
  const SurfaceTemplate(
    this.id,
    this.name,
    this.preferredKinds,
    this.rationale,
  );
  final String id, name, rationale;
  final List<SurfaceKind> preferredKinds;
}

class SurfaceTemplateLibrary {
  const SurfaceTemplateLibrary();
  List<SurfaceTemplate> get all => const [
    SurfaceTemplate('flange', 'Flange', [
      SurfaceKind.plane,
      SurfaceKind.cylinder,
    ], 'Planar mounting and cylindrical location regions'),
    SurfaceTemplate('shaft', 'Shaft', [
      SurfaceKind.cylinder,
      SurfaceKind.cone,
      SurfaceKind.revolution,
    ], 'Predominantly coaxial analytical construction'),
    SurfaceTemplate('housing', 'Housing', [
      SurfaceKind.plane,
      SurfaceKind.cylinder,
      SurfaceKind.patch,
    ], 'Mixed functional and transition regions'),
    SurfaceTemplate('sheet', 'Sheet metal', [
      SurfaceKind.plane,
      SurfaceKind.extrusion,
    ], 'Developable and constant-section regions'),
    SurfaceTemplate('casting', 'Casting', [
      SurfaceKind.patch,
      SurfaceKind.loft,
      SurfaceKind.blend,
    ], 'Drafted regions and blended transitions'),
    SurfaceTemplate('mold', 'Mold', [
      SurfaceKind.plane,
      SurfaceKind.nurbs,
      SurfaceKind.patch,
    ], 'Parting and freeform regions'),
    SurfaceTemplate('plastic', 'Plastic part', [
      SurfaceKind.nurbs,
      SurfaceKind.patch,
      SurfaceKind.blend,
    ], 'Thin freeform transitions'),
    SurfaceTemplate('automotive', 'Automotive', [
      SurfaceKind.nurbs,
      SurfaceKind.sweep,
      SurfaceKind.loft,
    ], 'Guided freeform continuity'),
    SurfaceTemplate('turbine', 'Turbine', [
      SurfaceKind.sweep,
      SurfaceKind.loft,
      SurfaceKind.nurbs,
    ], 'Blade guide and section behavior'),
    SurfaceTemplate('aerospace', 'Aerospace', [
      SurfaceKind.nurbs,
      SurfaceKind.loft,
      SurfaceKind.patch,
    ], 'High-continuity aerodynamic regions'),
  ];
  SurfaceTemplate? find(String id) => all.where((e) => e.id == id).firstOrNull;
}
