import '../../smart_regions/selection/triangle_selection.dart';

class SmartRegionCopy {
  const SmartRegionCopy({
    required this.id,
    required this.sourceRegionId,
    required this.meshAssetId,
    required this.selection,
    required this.mask,
    required this.dependencyIds,
    required this.createdAt,
  });
  final String id, sourceRegionId, meshAssetId;
  final TriangleSelection selection;
  final Map<int, double> mask;
  final List<String> dependencyIds;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceRegionId': sourceRegionId,
    'meshAssetId': meshAssetId,
    'selectionRanges': selection.toRanges(),
    'mask': mask.map((k, v) => MapEntry('$k', v)),
    'dependencyIds': dependencyIds,
    'createdAt': createdAt.toIso8601String(),
  };
  factory SmartRegionCopy.fromJson(Map<String, dynamic> j) => SmartRegionCopy(
    id: j['id'] as String,
    sourceRegionId: j['sourceRegionId'] as String,
    meshAssetId: j['meshAssetId'] as String,
    selection: TriangleSelection.fromRanges(
      (j['selectionRanges'] as List)
          .map((e) => (e as List).cast<int>())
          .toList(),
    ),
    mask: (j['mask'] as Map? ?? const {}).map(
      (k, v) => MapEntry(int.parse(k as String), (v as num).toDouble()),
    ),
    dependencyIds: (j['dependencyIds'] as List? ?? const []).cast(),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
