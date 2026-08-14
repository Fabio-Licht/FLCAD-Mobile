import '../../engineering_studio/models/studio_models.dart';
import '../engine/alignment_engine.dart';

class AlignmentStudioAdapter {
  const AlignmentStudioAdapter();
  static const workspace = 'Alignment Workspace';
  static const panels = [
    'Alignment Manager',
    'Alignment Preview',
    'Alignment Diagnostics',
    'Alignment History',
    'Reference Mapping',
    'Alignment Analytics',
  ];
  List<EngineeringTreeNode> buildTree(
    AlignmentEngine engine,
    String projectId,
  ) => [
    for (final panel in panels)
      EngineeringTreeNode(
        id: 'alignment:${panel.toLowerCase().replaceAll(' ', '-')}',
        projectId: projectId,
        name: panel,
        type: StudioEntityType.reference,
      ),
    for (final a in engine.alignments.values)
      EngineeringTreeNode(
        id: a.id,
        projectId: projectId,
        name: '${a.type.name} alignment',
        type: StudioEntityType.feature,
        parentId: 'alignment:alignment-manager',
        context: {
          'alignmentFeature': true,
          'alignmentType': a.type.name,
          'references': [
            ...a.input.movingReferences.map((e) => e.id),
            ...a.input.fixedReferences.map((e) => e.id),
          ],
          'transformation': a.parameters.toJson(),
          'matrix': a.parameters.matrix.toJson(),
          'rotation': a.parameters.rotation.toJson(),
          'translation': a.parameters.translation.toJson(),
          'quality': engine.quality(a.id).overall,
          'accuracy': 1 - a.rms,
          'history': engine.history.entries
              .where((e) => e.target == a.id)
              .map((e) => e.toJson())
              .toList(),
          'persistentId': a.id,
        },
      ),
  ];
}
