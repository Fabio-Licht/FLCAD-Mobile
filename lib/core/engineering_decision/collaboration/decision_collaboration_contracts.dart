import '../models/decision_models.dart';

class DecisionReview {
  const DecisionReview(
    this.decisionId,
    this.reviewerId,
    this.status,
    this.comment,
    this.timestamp,
  );
  final String decisionId, reviewerId, comment;
  final DecisionStatus status;
  final DateTime timestamp;
}

abstract interface class CollaborativeDecisionGateway {
  Future<List<DecisionReview>> reviews(String projectId, String decisionId);
  Future<void> submit(String projectId, DecisionReview review);
}
