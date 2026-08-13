import 'dart:convert';
import '../models/reconstruction_models.dart';

class WorkflowSerialization {
  const WorkflowSerialization();
  String encode(ReconstructionWorkflow w) => jsonEncode({
    'schema': 'flcad.autonomous-reconstruction',
    'version': '0.9.0',
    'id': w.id,
    'projectId': w.projectId,
    'meshId': w.meshId,
    'revision': w.revision,
    'selectedStrategyId': w.selectedStrategyId,
    'paused': w.paused,
    'createdAt': w.createdAt.toIso8601String(),
    'updatedAt': w.updatedAt.toIso8601String(),
    'stages': w.stages
        .map(
          (s) => {
            'id': s.id,
            'type': s.type.name,
            'name': s.name,
            'order': s.order,
            'priority': s.priority,
            'dependencies': s.dependencies,
            'sourceIds': s.sourceIds,
            'status': s.status.name,
            'parallelGroup': s.parallelGroup,
            'decision': {
              'confidence': s.decision.confidence,
              'risk': s.decision.risk.name,
              'alternatives': s.decision.alternatives,
              'impact': s.decision.impact,
              'explanation': s.decision.explanation,
              'evidence': s.decision.evidence
                  .map(
                    (e) => {
                      'id': e.id,
                      'description': e.description,
                      'value': e.value,
                      'source': e.source,
                    },
                  )
                  .toList(),
            },
          },
        )
        .toList(),
  });
}
