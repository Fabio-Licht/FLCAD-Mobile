import '../models/smart_region.dart';
import '../models/geometry.dart';
import '../models/region_dna.dart';
import '../models/region_statistics.dart';
import '../selection/triangle_selection.dart';

abstract final class SmartRegionSerializer {
  static Map<String, dynamic> toJson(SmartRegion r) => {
    'id': r.id,
    'projectId': r.projectId,
    'meshId': r.meshId,
    'dna': r.dna.toJson(),
    'name': r.name,
    'description': r.description,
    'color': r.color,
    'visible': r.visible,
    'locked': r.locked,
    'favorite': r.favorite,
    'confidence': r.confidence,
    'layerId': r.layerId,
    'groupId': r.groupId,
    'tags': r.tags,
    'metadata': r.metadata,
    'attributes': r.attributes,
    'createdAt': r.createdAt.toIso8601String(),
    'updatedAt': r.updatedAt.toIso8601String(),
    'triangleCount': r.triangleCount,
    'vertexCount': r.vertexCount,
    'boundingBox': r.boundingBox.toJson(),
    'statistics': r.statistics.toJson(),
    'selection': r.selection.toRanges(),
    'kind': r.kind.name,
    'liveFilter': r.liveFilter,
    'weights': r.weights.map((k, v) => MapEntry('$k', v)),
  };
  static SmartRegion fromJson(Map<String, dynamic> j) => SmartRegion(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    meshId: j['meshId'] as String,
    dna: RegionDNA.fromJson((j['dna'] as Map).cast()),
    name: j['name'] as String,
    description: j['description'] as String,
    color: j['color'] as String,
    visible: j['visible'] as bool,
    locked: j['locked'] as bool,
    favorite: j['favorite'] as bool,
    confidence: (j['confidence'] as num).toDouble(),
    layerId: j['layerId'] as String,
    groupId: j['groupId'] as String?,
    tags: (j['tags'] as List).cast<String>(),
    metadata: (j['metadata'] as Map).cast(),
    attributes: (j['attributes'] as Map).cast(),
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    triangleCount: j['triangleCount'] as int,
    vertexCount: j['vertexCount'] as int,
    boundingBox: BoundingBox.fromJson((j['boundingBox'] as Map).cast()),
    statistics: RegionStatistics.fromJson((j['statistics'] as Map).cast()),
    selection: TriangleSelection.fromRanges(j['selection'] as List),
    kind: RegionKind.values.firstWhere((v) => v.name == j['kind']),
    liveFilter: j['liveFilter'] as String?,
    weights: ((j['weights'] as Map?) ?? {}).map(
      (k, v) => MapEntry(int.parse('$k'), (v as num).toDouble()),
    ),
  );
}
