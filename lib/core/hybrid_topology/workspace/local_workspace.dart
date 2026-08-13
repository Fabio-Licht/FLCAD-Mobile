import '../../smart_regions/selection/triangle_selection.dart';

class LocalWorkspace {
  const LocalWorkspace({
    required this.id,
    required this.projectId,
    required this.objectId,
    required this.meshAssetId,
    required this.selection,
    required this.sourceRegionIds,
    required this.createdAt,
    this.shared = false,
    this.metadata = const {},
  });
  final String id, projectId, objectId, meshAssetId;
  final TriangleSelection selection;
  final List<String> sourceRegionIds;
  final DateTime createdAt;
  final bool shared;
  final Map<String, dynamic> metadata;
  int get referencedTriangleCount => selection.length;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'objectId': objectId,
    'meshAssetId': meshAssetId,
    'selectionRanges': selection.toRanges(),
    'sourceRegionIds': sourceRegionIds,
    'createdAt': createdAt.toIso8601String(),
    'shared': shared,
    'metadata': metadata,
  };
  factory LocalWorkspace.fromJson(Map<String, dynamic> j) => LocalWorkspace(
    id: j['id'] as String,
    projectId: j['projectId'] as String,
    objectId: j['objectId'] as String,
    meshAssetId: j['meshAssetId'] as String,
    selection: TriangleSelection.fromRanges(
      (j['selectionRanges'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
    ),
    sourceRegionIds: (j['sourceRegionIds'] as List).cast(),
    createdAt: DateTime.parse(j['createdAt'] as String),
    shared: j['shared'] as bool? ?? false,
    metadata: (j['metadata'] as Map? ?? const {}).cast(),
  );
}
