import 'dart:collection';

/// The durable CAD meaning of a managed import.  It is deliberately separate
/// from the scene mesh, which is only a presentation of BREP/STEP geometry.
enum ManagedCadSemanticKind { mesh, solid, surface }

final class ManagedCadIdentity {
  const ManagedCadIdentity._({
    required this.kind,
    required this.format,
    this.technicalName,
  });

  final ManagedCadSemanticKind kind;
  final String format;
  final String? technicalName;

  String get categoryLabel => switch (kind) {
    ManagedCadSemanticKind.mesh => 'Meshes',
    ManagedCadSemanticKind.solid => 'Solids',
    ManagedCadSemanticKind.surface => 'Surfaces',
  };

  String get visualTypeLabel => switch ((format, kind)) {
    ('stl', _) => 'Malha STL',
    ('step', ManagedCadSemanticKind.solid) => 'Sólido STEP',
    ('step', ManagedCadSemanticKind.surface) => 'Superfície STEP',
    ('brep', ManagedCadSemanticKind.solid) => 'Sólido BREP',
    ('brep', ManagedCadSemanticKind.surface) => 'Superfície BREP',
    _ => 'Geometria CAD',
  };

  Map<String, dynamic> toDocumentData() => {
    'cadSemanticKind': kind.name,
    'cadVisualType': visualTypeLabel,
    if (technicalName != null) 'stepTechnicalName': technicalName,
  };

  static ManagedCadIdentity stl() => const ManagedCadIdentity._(
    kind: ManagedCadSemanticKind.mesh,
    format: 'stl',
  );

  /// A native shape's topological root, never its display mesh, decides its
  /// semantic category. A true `solid` is closed and volumetric; faces,
  /// shells and non-volumetric compounds remain surfaces.
  static ManagedCadIdentity shape({
    required String format,
    required String shapeType,
    String? technicalName,
  }) => ManagedCadIdentity._(
    kind: shapeType == 'solid'
        ? ManagedCadSemanticKind.solid
        : ManagedCadSemanticKind.surface,
    format: format,
    technicalName: technicalName,
  );

  /// Reads the persisted contract. The fallback keeps documents produced by
  /// earlier versions legible while all newly imported managed geometry writes
  /// the explicit durable fields.
  static ManagedCadIdentity? fromDocumentData(Map<String, dynamic> data) {
    final format = data['format'];
    if (format is! String) return null;
    final technicalName = data['stepTechnicalName'];
    final storedKind = data['cadSemanticKind'];
    if (storedKind is String) {
      try {
        return ManagedCadIdentity._(
          kind: ManagedCadSemanticKind.values.byName(storedKind),
          format: format,
          technicalName: technicalName is String ? technicalName : null,
        );
      } on ArgumentError {
        return null;
      }
    }
    if (data['managedStlAssets'] is Map || format == 'stl') return stl();
    final descriptor = data['shapeDescriptor'];
    final shapeType = descriptor is Map ? descriptor['type'] : null;
    return shape(
      format: format,
      shapeType: shapeType is String ? shapeType : 'surface',
      technicalName: technicalName is String ? technicalName : null,
    );
  }
}

/// Preserves the source basename and only adds a deterministic suffix for a
/// collision.  Matching is case-insensitive because Windows source names are.
String managedCadImportName(String sourceDisplayName, Iterable<String> names) {
  final base = sourceDisplayName;
  if (base.trim().isEmpty) return 'Imported CAD';
  final occupied = HashSet<String>.of(names.map((name) => name.toLowerCase()));
  if (!occupied.contains(base.toLowerCase())) return base;
  var copy = 2;
  while (occupied.contains('$base ($copy)'.toLowerCase())) {
    copy++;
  }
  return '$base ($copy)';
}
