enum FeatureKind {
  extrude,
  revolve,
  sweep,
  loft,
  hole,
  pocket,
  slot,
  boss,
  rib,
  web,
  fillet,
  chamfer,
  draft,
  shell,
  offset,
  mirror,
  pattern,
  boolean,
  boundaryFill,
  surfaceTrim,
  surfaceExtend,
}

enum FeatureMode { staticFeature, live }

enum FeatureStatus { created, pendingKernel, valid, stale, invalid, suppressed }

enum ManufacturingStrategy {
  unknown,
  machining,
  additive,
  casting,
  injectionMolding,
  forming,
}

enum InspectionStrategy { unknown, dimensional, visual, cmm, scan, gauge }

class FeatureDNA {
  const FeatureDNA(
    this.originSignature,
    this.intentSignature,
    this.parameterSignature,
    this.manufacturingSignature,
    this.inspectionSignature,
    this.relationSignature,
    this.hash,
  );
  final String originSignature,
      intentSignature,
      parameterSignature,
      manufacturingSignature,
      inspectionSignature,
      relationSignature,
      hash;
  Map<String, dynamic> toJson() => {
    'originSignature': originSignature,
    'intentSignature': intentSignature,
    'parameterSignature': parameterSignature,
    'manufacturingSignature': manufacturingSignature,
    'inspectionSignature': inspectionSignature,
    'relationSignature': relationSignature,
    'hash': hash,
  };
  factory FeatureDNA.fromJson(Map<String, dynamic> j) => FeatureDNA(
    j['originSignature'] as String,
    j['intentSignature'] as String,
    j['parameterSignature'] as String,
    j['manufacturingSignature'] as String,
    j['inspectionSignature'] as String,
    j['relationSignature'] as String,
    j['hash'] as String,
  );
}

class EngineeringFeature {
  const EngineeringFeature({
    required this.id,
    required this.projectId,
    required this.name,
    required this.kind,
    required this.mode,
    required this.status,
    required this.parameters,
    required this.sourceIds,
    required this.dependencyIds,
    required this.referenceIds,
    required this.intent,
    required this.manufacturing,
    required this.inspection,
    required this.dna,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.kernelResultId,
    this.metadata = const {},
  });
  final String id, projectId, name;
  final FeatureKind kind;
  final FeatureMode mode;
  final FeatureStatus status;
  final Map<String, dynamic> parameters;
  final List<String> sourceIds, dependencyIds, referenceIds;
  final String intent;
  final ManufacturingStrategy manufacturing;
  final InspectionStrategy inspection;
  final FeatureDNA dna;
  final int version;
  final DateTime createdAt, updatedAt;
  final String? kernelResultId;
  final Map<String, dynamic> metadata;
  EngineeringFeature copyWith({
    FeatureStatus? status,
    Map<String, dynamic>? parameters,
    FeatureDNA? dna,
    int? version,
    DateTime? updatedAt,
    String? kernelResultId,
    Map<String, dynamic>? metadata,
  }) => EngineeringFeature(
    id: id,
    projectId: projectId,
    name: name,
    kind: kind,
    mode: mode,
    status: status ?? this.status,
    parameters: parameters ?? this.parameters,
    sourceIds: sourceIds,
    dependencyIds: dependencyIds,
    referenceIds: referenceIds,
    intent: intent,
    manufacturing: manufacturing,
    inspection: inspection,
    dna: dna ?? this.dna,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    kernelResultId: kernelResultId ?? this.kernelResultId,
    metadata: metadata ?? this.metadata,
  );
}
