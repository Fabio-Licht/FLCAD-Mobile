import '../../smart_regions/models/smart_region.dart';
import '../../utils/id_generator.dart';
import '../hybrid/hybrid_object.dart';
import '../selection/smart_copy.dart';
import 'local_workspace.dart';

class WorkspaceService {
  const WorkspaceService();
  LocalWorkspace create(
    HybridObject object,
    SmartRegion region,
    String meshAssetId,
  ) => LocalWorkspace(
    id: IdGenerator.generate(),
    projectId: object.projectId,
    objectId: object.id,
    meshAssetId: meshAssetId,
    selection: region.selection,
    sourceRegionIds: [region.id],
    createdAt: DateTime.now(),
  );
  SmartRegionCopy smartCopy(
    SmartRegion region,
    String meshAssetId, {
    List<String> dependencies = const [],
  }) => SmartRegionCopy(
    id: IdGenerator.generate(),
    sourceRegionId: region.id,
    meshAssetId: meshAssetId,
    selection: region.selection,
    mask: region.weights,
    dependencyIds: dependencies,
    createdAt: DateTime.now(),
  );
}
