import '../../engineering_studio/models/studio_models.dart';
import '../engine/profile_recognition_engine.dart';

class ProfileStudioAdapter {
  const ProfileStudioAdapter();
  static const panels = [
    'Profiles',
    'Regions',
    'Loops',
    'Topology',
    'Intent',
    'Feature Readiness',
    'Quality',
    'Advisor',
  ];
  List<EngineeringTreeNode> buildTree(
    ProfileRecognitionEngine e,
    String projectId,
  ) {
    final nodes = <EngineeringTreeNode>[
      for (final name in panels)
        EngineeringTreeNode(
          id: 'profile:${name.toLowerCase().replaceAll(' ', '-')}',
          projectId: projectId,
          name: name,
          type: StudioEntityType.sketch,
        ),
    ];
    for (final p in e.profiles.values) {
      nodes.add(
        EngineeringTreeNode(
          id: p.id,
          projectId: projectId,
          name: p.type.name,
          type: StudioEntityType.sketch,
          parentId: 'profile:profiles',
          context: {
            'profileRecognition': true,
            'profileType': p.type.name,
            'loopCount': e.loops.values
                .where((l) => l.profileId == p.id)
                .length,
            'regionCount': e.regions.values
                .where(
                  (r) => r.loopIds.any((id) => e.loops[id]?.profileId == p.id),
                )
                .length,
            'area': p.area,
            'perimeter': p.perimeter,
            'orientation': e.loops.values
                .where((l) => l.profileId == p.id)
                .firstOrNull
                ?.orientation
                .name,
            'topologyStatus': p.diagnostics.isEmpty ? 'valid' : 'diagnostic',
            'readiness': e.lastReadiness?.toJson(),
            'quality': e.lastQuality?.score,
            'intent': e.intent.intent.name,
            'confidence': p.confidence,
            'persistentId': p.id,
          },
        ),
      );
    }
    return nodes;
  }
}
