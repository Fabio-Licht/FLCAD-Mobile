import '../selection/triangle_selection.dart';
import 'geometry.dart';
import 'region_dna.dart';
import 'region_statistics.dart';

enum RegionKind { staticRegion, liveRegion, proceduralRegion }

class SmartRegion {
  const SmartRegion({
    required this.id,
    required this.projectId,
    required this.meshId,
    required this.dna,
    required this.name,
    required this.description,
    required this.color,
    required this.visible,
    required this.locked,
    required this.favorite,
    required this.confidence,
    required this.layerId,
    required this.tags,
    required this.metadata,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
    required this.triangleCount,
    required this.vertexCount,
    required this.boundingBox,
    required this.statistics,
    required this.selection,
    this.groupId,
    this.kind = RegionKind.staticRegion,
    this.liveFilter,
    this.weights = const {},
  });
  final String id, projectId, meshId, name, description, color, layerId;
  final RegionDNA dna;
  final bool visible, locked, favorite;
  final double confidence;
  final String? groupId, liveFilter;
  final List<String> tags;
  final Map<String, dynamic> metadata, attributes;
  final DateTime createdAt, updatedAt;
  final int triangleCount, vertexCount;
  final BoundingBox boundingBox;
  final RegionStatistics statistics;
  final TriangleSelection selection;
  final RegionKind kind;
  final Map<int, double> weights;

  SmartRegion copyWith({
    RegionDNA? dna,
    String? name,
    String? description,
    String? color,
    bool? visible,
    bool? locked,
    bool? favorite,
    double? confidence,
    String? layerId,
    String? groupId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? attributes,
    DateTime? updatedAt,
    int? triangleCount,
    int? vertexCount,
    BoundingBox? boundingBox,
    RegionStatistics? statistics,
    TriangleSelection? selection,
    RegionKind? kind,
    String? liveFilter,
    Map<int, double>? weights,
  }) => SmartRegion(
    id: id,
    projectId: projectId,
    meshId: meshId,
    dna: dna ?? this.dna,
    name: name ?? this.name,
    description: description ?? this.description,
    color: color ?? this.color,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    favorite: favorite ?? this.favorite,
    confidence: confidence ?? this.confidence,
    layerId: layerId ?? this.layerId,
    groupId: groupId ?? this.groupId,
    tags: tags ?? this.tags,
    metadata: metadata ?? this.metadata,
    attributes: attributes ?? this.attributes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    triangleCount: triangleCount ?? this.triangleCount,
    vertexCount: vertexCount ?? this.vertexCount,
    boundingBox: boundingBox ?? this.boundingBox,
    statistics: statistics ?? this.statistics,
    selection: selection ?? this.selection,
    kind: kind ?? this.kind,
    liveFilter: liveFilter ?? this.liveFilter,
    weights: weights ?? this.weights,
  );
}
