import '../../cad_kernel/models/kernel_models.dart';

enum TopologicalEntityType { vertex, edge, wire, face, shell, solid }

enum TopologicalContinuity { g0, g1, g2 }

enum TopologicalAssociationState { current, outdated, detached }

/// Persistent topology owned by CadDocument. Geometry remains owned by OCCT
/// through [handle]; IDs below describe explicit incidence and adjacency.
class TopologicalEntity {
  const TopologicalEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.handle,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.vertexIds = const [],
    this.edgeIds = const [],
    this.wireIds = const [],
    this.faceIds = const [],
    this.adjacentIds = const [],
    this.supportGeometryId,
    this.outerWireId,
    this.innerWireIds = const [],
    this.continuity = TopologicalContinuity.g0,
    this.associationState = TopologicalAssociationState.current,
    this.tolerance = 1e-7,
    this.closed = false,
    this.manifold = true,
    this.metadata = const {},
  });

  final String id, name;
  final TopologicalEntityType type;
  final ShapeHandle handle;
  final int revision;
  final List<String> vertexIds, edgeIds, wireIds, faceIds, adjacentIds;
  final String? supportGeometryId, outerWireId;
  final List<String> innerWireIds;
  final TopologicalContinuity continuity;
  final TopologicalAssociationState associationState;
  final double tolerance;
  final bool closed, manifold;
  final DateTime createdAt, updatedAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'handle': handle.toJson(),
    'revision': revision,
    'vertexIds': vertexIds,
    'edgeIds': edgeIds,
    'wireIds': wireIds,
    'faceIds': faceIds,
    'adjacentIds': adjacentIds,
    'supportGeometryId': supportGeometryId,
    'outerWireId': outerWireId,
    'innerWireIds': innerWireIds,
    'continuity': continuity.name,
    'associationState': associationState.name,
    'tolerance': tolerance,
    'closed': closed,
    'manifold': manifold,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'metadata': metadata,
  };

  factory TopologicalEntity.fromJson(
    Map<String, dynamic> json,
  ) => TopologicalEntity(
    id: json['id'] as String,
    name: json['name'] as String,
    type: TopologicalEntityType.values.byName(json['type'] as String),
    handle: ShapeHandle.fromJson(
      Map<String, dynamic>.from(json['handle'] as Map),
    ),
    revision: json['revision'] as int,
    vertexIds: (json['vertexIds'] as List? ?? const []).cast<String>(),
    edgeIds: (json['edgeIds'] as List? ?? const []).cast<String>(),
    wireIds: (json['wireIds'] as List? ?? const []).cast<String>(),
    faceIds: (json['faceIds'] as List? ?? const []).cast<String>(),
    adjacentIds: (json['adjacentIds'] as List? ?? const []).cast<String>(),
    supportGeometryId: json['supportGeometryId'] as String?,
    outerWireId: json['outerWireId'] as String?,
    innerWireIds: (json['innerWireIds'] as List? ?? const []).cast<String>(),
    continuity: TopologicalContinuity.values.byName(
      json['continuity'] as String? ?? 'g0',
    ),
    associationState: TopologicalAssociationState.values.byName(
      json['associationState'] as String? ?? 'current',
    ),
    tolerance: (json['tolerance'] as num? ?? 1e-7).toDouble(),
    closed: json['closed'] as bool? ?? false,
    manifold: json['manifold'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
  );
}
