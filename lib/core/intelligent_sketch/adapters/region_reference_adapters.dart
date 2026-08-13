import '../../reference_engine/models/reference_entity.dart';
import '../../smart_regions/models/smart_region.dart';
import '../models/sketch_context.dart';

class SketchContextFactory {
  const SketchContextFactory();
  SketchGeometryContext fromRegion(SmartRegion region) => SketchGeometryContext(
    id: 'region:${region.id}',
    kind: SketchContextKind.region,
    sourceId: region.id,
    fingerprint: region.dna.hash,
  );
  SketchGeometryContext fromReference(ReferenceEntity reference) =>
      SketchGeometryContext(
        id: 'reference:${reference.id}',
        kind: reference.geometry.type == 'plane'
            ? SketchContextKind.plane
            : SketchContextKind.hybrid,
        sourceId: reference.id,
        fingerprint: reference.dna.hash,
        metadata: {'referenceType': reference.geometry.type},
      );
  SketchGeometryContext fromSurface({
    required String id,
    required SketchContextKind kind,
    required String fingerprint,
  }) {
    if (!{
      SketchContextKind.surface,
      SketchContextKind.cylinder,
      SketchContextKind.cone,
      SketchContextKind.sphere,
      SketchContextKind.torus,
      SketchContextKind.nurbs,
    }.contains(kind)) {
      throw ArgumentError('Not a surface context');
    }
    return SketchGeometryContext(
      id: 'surface:$id',
      kind: kind,
      sourceId: id,
      fingerprint: fingerprint,
    );
  }
}
