import '../../cad_kernel/models/kernel_models.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../../utils/id_generator.dart';

enum ExtrudeType {
  blind,
  midPlane,
  symmetric,
  twoDirections,
  upToPlane,
  upToFace,
  upToNext,
  upToVertex,
  offsetFromFace,
  thin,
  cut,
  boss,
  newBody,
  mergeResult,
  surface,
  draft,
}

enum ExtrudeStatus {
  prepared,
  previewed,
  executing,
  success,
  kernelUnavailable,
  unsupportedOperation,
  invalid,
  failed,
  suppressed,
  rolledBack,
}

class ExtrudeSelectionFilter {
  const ExtrudeSelectionFilter({
    this.allowClosed = true,
    this.allowOpen = false,
    this.allowMultiple = true,
  });
  final bool allowClosed, allowOpen, allowMultiple;
}

class ExtrudeParameters {
  ExtrudeParameters({
    this.type = ExtrudeType.blind,
    this.distance = 1,
    this.secondDistance = 0,
    this.direction = const SketchVector(0, 0, 1),
    this.reverse = false,
    this.draftAngle = 0,
    this.offset = 0,
    this.merge = false,
    this.thickness = 0,
    this.bodyTarget,
    this.surfaceTarget,
    this.referencePlane,
    this.referenceFace,
    this.referenceAxis,
    this.selectionFilter = const ExtrudeSelectionFilter(),
  });
  ExtrudeType type;
  double distance, secondDistance, draftAngle, offset, thickness;
  SketchVector direction;
  bool reverse, merge;
  String? bodyTarget,
      surfaceTarget,
      referencePlane,
      referenceFace,
      referenceAxis;
  ExtrudeSelectionFilter selectionFilter;
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'distance': distance,
    'secondDistance': secondDistance,
    'direction': direction.toJson(),
    'reverse': reverse,
    'draftAngle': draftAngle,
    'offset': offset,
    'merge': merge,
    'thickness': thickness,
    'bodyTarget': bodyTarget,
    'surfaceTarget': surfaceTarget,
    'referencePlane': referencePlane,
    'referenceFace': referenceFace,
    'referenceAxis': referenceAxis,
  };
}

class ExtrudeInput {
  ExtrudeInput({
    required this.sketchId,
    required List<String> profileIds,
    List<String>? regionIds,
    this.kernelProfile,
    this.multipleProfiles = false,
    this.nestedRegions = false,
  }) : profileIds = List.of(profileIds),
       regionIds = regionIds ?? <String>[];
  final String sketchId;
  final List<String> profileIds, regionIds;
  final ShapeHandle? kernelProfile;
  final bool multipleProfiles, nestedRegions;
}

class ExtrudeFeature {
  ExtrudeFeature({
    required this.input,
    required this.parameters,
    String? id,
    DateTime? timestamp,
    this.owner = 'local',
  }) : id = id ?? 'extrude:${IdGenerator.generate()}',
       timestamp = timestamp ?? DateTime.now().toUtc();
  final String id, owner;
  final ExtrudeInput input;
  final ExtrudeParameters parameters;
  final DateTime timestamp;
  int version = 1;
  ExtrudeStatus status = ExtrudeStatus.prepared;
  ShapeHandle? output;
  final List<String> diagnostics = [], history = [], dependencies = [];
  String? platformFeatureId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sketchId': input.sketchId,
    'profileIds': input.profileIds,
    'regionIds': input.regionIds,
    'kernelProfile': input.kernelProfile?.toJson(),
    'multipleProfiles': input.multipleProfiles,
    'nestedRegions': input.nestedRegions,
    'parameters': parameters.toJson(),
    'owner': owner,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'status': status.name,
    'output': output?.toJson(),
    'diagnostics': diagnostics,
    'history': history,
    'dependencies': dependencies,
    'platformFeatureId': platformFeatureId,
  };
}

class ExtrudeExecutionResult {
  const ExtrudeExecutionResult(
    this.status, {
    this.shape,
    this.diagnostics = const [],
  });
  final ExtrudeStatus status;
  final ShapeHandle? shape;
  final List<String> diagnostics;
  bool get success => status == ExtrudeStatus.success && shape != null;
}
