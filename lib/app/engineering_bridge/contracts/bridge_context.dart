import 'bridge_selection.dart';

class BridgeContext {
  const BridgeContext({
    required this.projectId,
    required this.meshId,
    required this.meshFingerprint,
    required this.userConfirmed,
    this.region,
    this.attributes = const {},
  });
  final String projectId, meshId, meshFingerprint;
  final bool userConfirmed;
  final MeshRegion? region;
  final Map<String, Object?> attributes;
  BridgeContext copyWith({
    MeshRegion? region,
    bool? userConfirmed,
    Map<String, Object?>? attributes,
  }) => BridgeContext(
    projectId: projectId,
    meshId: meshId,
    meshFingerprint: meshFingerprint,
    userConfirmed: userConfirmed ?? this.userConfirmed,
    region: region ?? this.region,
    attributes: attributes ?? this.attributes,
  );
}
