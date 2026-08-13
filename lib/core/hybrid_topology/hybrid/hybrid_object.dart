enum HybridGeometryKind {
  triangleMesh,
  quadMesh,
  polygonMesh,
  pointCloud,
  voxelGrid,
  implicitSurface,
  cadSurface,
  solid,
  subdivisionSurface,
}

enum HybridObjectMode { staticObject, live }

class GeometryAssetRef {
  const GeometryAssetRef(
    this.id,
    this.kind,
    this.uri,
    this.fingerprint, {
    this.metadata = const {},
  });
  final String id, uri, fingerprint;
  final HybridGeometryKind kind;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'uri': uri,
    'fingerprint': fingerprint,
    'metadata': metadata,
  };
  factory GeometryAssetRef.fromJson(Map<String, dynamic> j) => GeometryAssetRef(
    j['id'] as String,
    HybridGeometryKind.values.byName(j['kind'] as String),
    j['uri'] as String,
    j['fingerprint'] as String,
    metadata: (j['metadata'] as Map? ?? const {}).cast(),
  );
}

class TopologyDNA {
  const TopologyDNA(
    this.sourceFingerprint,
    this.layerSignature,
    this.relationSignature,
    this.hash,
  );
  final String sourceFingerprint, layerSignature, relationSignature, hash;
  Map<String, dynamic> toJson() => {
    'sourceFingerprint': sourceFingerprint,
    'layerSignature': layerSignature,
    'relationSignature': relationSignature,
    'hash': hash,
  };
  factory TopologyDNA.fromJson(Map<String, dynamic> j) => TopologyDNA(
    j['sourceFingerprint'] as String,
    j['layerSignature'] as String,
    j['relationSignature'] as String,
    j['hash'] as String,
  );
}

class TopologyAnalytics {
  const TopologyAnalytics({
    required this.thickness,
    required this.curvature,
    required this.noise,
    required this.continuity,
    required this.density,
    required this.quality,
    required this.confidence,
    required this.vertexCount,
    required this.faceCount,
  });
  final double thickness,
      curvature,
      noise,
      continuity,
      density,
      quality,
      confidence;
  final int vertexCount, faceCount;
  Map<String, dynamic> toJson() => {
    'thickness': thickness,
    'curvature': curvature,
    'noise': noise,
    'continuity': continuity,
    'density': density,
    'quality': quality,
    'confidence': confidence,
    'vertexCount': vertexCount,
    'faceCount': faceCount,
  };
  factory TopologyAnalytics.fromJson(Map<String, dynamic> j) =>
      TopologyAnalytics(
        thickness: (j['thickness'] as num).toDouble(),
        curvature: (j['curvature'] as num).toDouble(),
        noise: (j['noise'] as num).toDouble(),
        continuity: (j['continuity'] as num).toDouble(),
        density: (j['density'] as num).toDouble(),
        quality: (j['quality'] as num).toDouble(),
        confidence: (j['confidence'] as num).toDouble(),
        vertexCount: j['vertexCount'] as int,
        faceCount: j['faceCount'] as int,
      );
}

class HybridObject {
  const HybridObject({
    required this.id,
    required this.projectId,
    required this.name,
    required this.mode,
    required this.assets,
    required this.regionIds,
    required this.referenceIds,
    required this.sketchIds,
    required this.surfaceIds,
    required this.solidIds,
    required this.layerIds,
    required this.dna,
    required this.analytics,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });
  final String id, projectId, name;
  final HybridObjectMode mode;
  final List<GeometryAssetRef> assets;
  final List<String> regionIds,
      referenceIds,
      sketchIds,
      surfaceIds,
      solidIds,
      layerIds;
  final TopologyDNA dna;
  final TopologyAnalytics analytics;
  final int version;
  final DateTime createdAt, updatedAt;
  final Map<String, dynamic> metadata;
  HybridObject copyWith({
    List<String>? layerIds,
    TopologyDNA? dna,
    TopologyAnalytics? analytics,
    int? version,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) => HybridObject(
    id: id,
    projectId: projectId,
    name: name,
    mode: mode,
    assets: assets,
    regionIds: regionIds,
    referenceIds: referenceIds,
    sketchIds: sketchIds,
    surfaceIds: surfaceIds,
    solidIds: solidIds,
    layerIds: layerIds ?? this.layerIds,
    dna: dna ?? this.dna,
    analytics: analytics ?? this.analytics,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    metadata: metadata ?? this.metadata,
  );
}
