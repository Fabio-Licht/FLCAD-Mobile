import '../../engineering_feature_intelligence/models/engineering_feature_models.dart';
import '../../reconstruction_strategy/models/reconstruction_strategy_models.dart';
import '../../smart_reference/models/smart_reference_models.dart';
import '../models/interactive_assistant_models.dart';

class EngineeringConversationLayer {
  const EngineeringConversationLayer();
  List<EngineeringMessage> messages(
    String sessionId,
    EngineeringFeatureSession features,
    SmartReferenceSession references,
    ReconstructionStrategySession strategies,
  ) {
    final evidence = _evidence(sessionId, features, references, strategies);
    final confidence = strategies.strategies.first.confidence;
    return List.unmodifiable([
      EngineeringMessage(
        id: '$sessionId:analysis',
        kind: AssistantMessageKind.analysis,
        title: 'Analysis completed',
        body:
            '${features.hypotheses.length} Features and ${references.candidates.length} Smart References were consolidated.',
        confidence: confidence,
        evidence: evidence,
      ),
      EngineeringMessage(
        id: '$sessionId:suggestion',
        kind: AssistantMessageKind.suggestion,
        title: 'Suggestion',
        body:
            'Reconstruction may start with ${strategies.playbook.steps.first.objective}.',
        confidence: confidence,
        evidence: evidence,
      ),
      EngineeringMessage(
        id: '$sessionId:observation',
        kind: AssistantMessageKind.observation,
        title: 'Observation',
        body:
            'Canonical references and dependency graphs are available for the active Playbook.',
        confidence: confidence,
        evidence: evidence,
      ),
    ]);
  }

  List<AssistantEvidence> _evidence(
    String sessionId,
    EngineeringFeatureSession features,
    SmartReferenceSession references,
    ReconstructionStrategySession strategies,
  ) => [
    AssistantEvidence(
      id: '$sessionId:evidence:features',
      source: 'engineeringFeatureIntelligence',
      description: 'Feature hypotheses used by the assistant.',
      entityIds: features.hypotheses.map((e) => e.id),
      score: features.hypotheses.first.scores.overallConfidence,
    ),
    AssistantEvidence(
      id: '$sessionId:evidence:references',
      source: 'smartReferenceSystem',
      description: 'Ranked Smart References used by the assistant.',
      entityIds: references.candidates.map((e) => e.id),
      score: references.candidates.first.scores.overallConfidence,
    ),
    AssistantEvidence(
      id: '$sessionId:evidence:playbook',
      source: 'reconstructionStrategyAI',
      description: 'Active auditable Engineering Playbook.',
      entityIds: [strategies.playbook.id],
      score: strategies.strategies.first.confidence,
    ),
  ];
}

class EngineeringQuestionEngine {
  const EngineeringQuestionEngine();
  EngineeringAnswer answer(
    EngineeringQuestion question,
    EngineeringFeatureSession features,
    SmartReferenceSession references,
    ReconstructionStrategySession strategies,
  ) {
    final strategy = strategies.strategies.first;
    final reference = references.candidates.first;
    final feature = features.hypotheses.first;
    final evidence = [
      AssistantEvidence(
        id: 'answer:${question.name}',
        source: 'explainableEngineeringChain',
        description:
            'Feature, reference and strategy evidence for ${question.name}.',
        entityIds: [feature.id, reference.id, strategy.id],
        score: strategy.confidence,
      ),
    ];
    final text = switch (question) {
      EngineeringQuestion.whyPlane =>
        'The plane is proposed because ${reference.justification}',
      EngineeringQuestion.whyAxis => strategy.reasoning.whyMainAxis,
      EngineeringQuestion.whyStrategy => strategy.justification,
      EngineeringQuestion.whichEvidence =>
        strategy.evidence.map((e) => e.description).join('; '),
      EngineeringQuestion.whichFeature =>
        'Feature ${feature.type.name} (${feature.id}) motivated the decision.',
      EngineeringQuestion.whichReference =>
        'Reference ${reference.type.name} (${reference.id}) is used by the active strategy.',
    };
    return EngineeringAnswer(
      question: question,
      answer: text,
      evidence: evidence,
    );
  }
}
