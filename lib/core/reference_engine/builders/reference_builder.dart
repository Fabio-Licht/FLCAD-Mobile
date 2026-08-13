import '../../smart_regions/models/geometry.dart';
import '../../smart_regions/models/smart_region.dart';
import '../models/reference_entity.dart';
import '../models/reference_geometry.dart';

class ReferenceBuildContext {
  const ReferenceBuildContext({
    required this.projectId,
    required this.meshes,
    required this.regions,
    required this.references,
  });
  final String projectId;
  final Map<String, MeshTopology> meshes;
  final Map<String, SmartRegion> regions;
  final Map<String, ReferenceEntity> references;
}

class ReferenceBuildResult {
  const ReferenceBuildResult(
    this.geometry,
    this.analytics,
    this.sourceFingerprint,
  );
  final ReferenceGeometry geometry;
  final ReferenceAnalytics analytics;
  final String sourceFingerprint;
}

abstract interface class ReferenceBuilder {
  String get id;
  Future<ReferenceBuildResult> build(
    ReferenceBuildContext context,
    ReferenceRecipe recipe,
  );
}

ReferenceDNA createReferenceDNA(
  String kind,
  String source,
  ReferenceGeometry geometry,
) {
  final signature = geometry.toJson().toString(),
      raw = '$kind:$source:$signature',
      hash = raw.codeUnits
          .fold<int>(17, (a, b) => 37 * a + b)
          .toUnsigned(32)
          .toRadixString(16);
  return ReferenceDNA(kind, source, signature, hash);
}
