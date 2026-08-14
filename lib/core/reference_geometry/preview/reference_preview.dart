import '../models/reference_models.dart';

class ReferenceBounds {
  const ReferenceBounds(this.width, this.height, this.depth);
  final double width, height, depth;
}

class ReferencePreview {
  const ReferencePreview({
    required this.referenceId,
    required this.kind,
    required this.origin,
    required this.orientation,
    required this.bounds,
    required this.readiness,
    required this.warnings,
  });
  final String referenceId, kind;
  final ReferenceVector origin, orientation;
  final ReferenceBounds bounds;
  final bool readiness;
  final List<String> warnings;
}

class ReferencePreviewEngine {
  const ReferencePreviewEngine();
  ReferencePreview create(ReferenceEntity entity) {
    final directional = {
          ReferenceType.datumPlane,
          ReferenceType.datumAxis,
          ReferenceType.coordinateSystem,
          ReferenceType.constructionPlane,
          ReferenceType.constructionAxis,
          ReferenceType.referenceFrame,
        }.contains(entity.type),
        valid =
            entity.parameters.origin.finite &&
            (!directional ||
                entity.parameters.direction.finite &&
                    !entity.parameters.direction.zero);
    return ReferencePreview(
      referenceId: entity.id,
      kind: entity.type.name,
      origin: entity.parameters.origin,
      orientation: entity.parameters.direction,
      bounds: const ReferenceBounds(10, 10, 10),
      readiness: valid,
      warnings: [if (!valid) 'Invalid reference orientation'],
    );
  }
}
