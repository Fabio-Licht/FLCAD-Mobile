import '../dna/engineering_dna.dart';

enum EngineeringEntityKind {
  project,
  mesh,
  pointCloud,
  region,
  reference,
  sketch,
  surface,
  topology,
  feature,
  solid,
  manufacturing,
  inspection,
}

class EngineeringEntityRef {
  const EngineeringEntityRef(
    this.id,
    this.kind, {
    this.version,
    this.fingerprint,
  });
  final String id;
  final EngineeringEntityKind kind;
  final int? version;
  final String? fingerprint;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'version': version,
    'fingerprint': fingerprint,
  };
}

class EngineeringObject {
  const EngineeringObject({
    required this.id,
    required this.projectId,
    required this.name,
    required this.entities,
    required this.dna,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.manufacturing = const {},
    this.inspection = const {},
    this.metadata = const {},
  });
  final String id, projectId, name;
  final List<EngineeringEntityRef> entities;
  final EngineeringDNA dna;
  final int version;
  final DateTime createdAt, updatedAt;
  final Map<String, dynamic> manufacturing, inspection, metadata;
  Iterable<EngineeringEntityRef> ofKind(EngineeringEntityKind kind) =>
      entities.where((e) => e.kind == kind);
}
