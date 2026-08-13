import '../solids/engineering_solid.dart';

class EngineeringObject {
  const EngineeringObject({
    required this.id,
    required this.projectId,
    required this.name,
    required this.meshIds,
    required this.pointCloudIds,
    required this.referenceIds,
    required this.sketchIds,
    required this.surfaceIds,
    required this.featureIds,
    required this.solids,
    required this.manufacturingData,
    required this.inspectionData,
    required this.version,
  });
  final String id, projectId, name;
  final List<String> meshIds,
      pointCloudIds,
      referenceIds,
      sketchIds,
      surfaceIds,
      featureIds;
  final List<EngineeringSolid> solids;
  final Map<String, dynamic> manufacturingData, inspectionData;
  final int version;
}
