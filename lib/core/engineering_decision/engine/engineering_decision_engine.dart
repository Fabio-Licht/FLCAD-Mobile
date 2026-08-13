import '../../engineering/runtime/engineering_runtime.dart';
import '../graph/decision_graph.dart';
import '../memory/decision_memory.dart';
import '../models/decision_models.dart';
import '../planning/alternative_planner.dart';
import '../plugins/decision_plugin.dart';
import '../policies/decision_policy.dart';
import '../repository/decision_repository.dart';
import '../scoring/multi_criteria_decision.dart';
import '../simulation/decision_simulator.dart';

class EngineeringDecisionEngine {
  EngineeringDecisionEngine({
    DecisionRepository? repository,
    DecisionMemory? memory,
    DecisionGraph? graph,
    DecisionPluginRegistry? plugins,
  }) : repository = repository ?? InMemoryDecisionRepository(),
       memory = memory ?? DecisionMemory(InMemoryDecisionMemoryStore()),
       graph = graph ?? DecisionGraph(),
       plugins = plugins ?? DecisionPluginRegistry();
  final DecisionRepository repository;
  final DecisionMemory memory;
  final DecisionGraph graph;
  final DecisionPluginRegistry plugins;
  final _scoring = const MultiCriteriaDecisionSystem();
  final _planner = const AlternativePlanner();
  final _simulator = const DecisionSimulator();
  final List<DecisionTimelineEntry> _timeline = [];
  DecisionPolicy _policy = DecisionPolicy.precision;
  DecisionPolicy get policy => _policy;
  void applyPolicy(DecisionPolicy value) => _policy = value;

  Future<EngineeringDecision> decide(DecisionRequest request) async {
    return EngineeringRuntime.shared
        .submit(
          'decision:${DateTime.now().microsecondsSinceEpoch}',
          () {
            var criteria = request.criteria;
            final evidence = [...request.evidence];
            for (final plugin in plugins.plugins) {
              criteria = plugin.evaluate(request);
              evidence.addAll(plugin.evidence(request));
            }
            final score = _scoring.score(
              criteria,
              DecisionPolicyProfile.forPolicy(_policy),
            );
            final alternatives = _planner.plan(score), now = DateTime.now();
            return EngineeringDecision(
              id: 'ede:${now.microsecondsSinceEpoch}',
              projectId: request.projectId,
              type: request.type,
              origin: request.origin,
              title: request.title,
              evidence: List.unmodifiable(evidence),
              confidence: score.value,
              priority: _priority(score.value),
              impact: request.impact,
              dependencies: request.dependencies,
              alternatives: alternatives,
              estimatedCost: 1 - score.components['cost']!,
              expectedBenefit: score.components['impact']!,
              risk: alternatives.first.risk,
              justification: _justify(request, score, evidence),
              timestamp: now,
              responsible: request.responsible,
              score: score,
              regionId: request.regionId,
            );
          },
          namespace: 'cognition',
        )
        .future
        .then((decision) async {
          graph.add(decision);
          await repository.save(decision);
          _record(
            decision,
            'created',
            decision.responsible,
            decision.justification,
          );
          return decision;
        });
  }

  Future<EngineeringDecision> override(
    String id,
    String projectId,
    DecisionStatus status, {
    required String actor,
    required String reason,
    String? replacementTitle,
  }) async {
    final current =
        await repository.findById(projectId, id) ??
        (throw StateError('Decision $id not found'));
    if (status == DecisionStatus.proposed) {
      throw ArgumentError('Override status required');
    }
    final updated = current.copyWith(
      status: status,
      title: replacementTitle,
      revision: current.revision + 1,
    );
    graph.update(updated);
    await repository.save(updated);
    await memory.record(
      projectId,
      DecisionMemoryRecord(
        id,
        status,
        reason,
        'pending-validation',
        DateTime.now(),
        actor,
      ),
    );
    _record(updated, status.name, actor, reason);
    return updated;
  }

  DecisionSimulationResult simulate(String decisionId, String alternativeId) {
    final decision =
        graph.find(decisionId) ??
        (throw StateError('Decision $decisionId not found'));
    final alternative = decision.alternatives.firstWhere(
      (item) => item.id == alternativeId,
    );
    return _simulator.simulate(
      decision,
      alternative,
      impacted: graph.impact(decisionId),
    );
  }

  List<DecisionTimelineEntry> get timeline => List.unmodifiable(_timeline);
  DecisionAnalytics analytics() {
    final decisions = graph.decisions,
        records = _timeline
            .where(
              (e) => const [
                'accepted',
                'rejected',
                'modified',
                'replaced',
              ].contains(e.action),
            )
            .toList();
    final accepted = records.where((e) => e.action == 'accepted').length;
    final corrected = records
        .where((e) => e.action == 'modified' || e.action == 'replaced')
        .length;
    final automatic = decisions
        .where((d) => d.origin != DecisionOrigin.user)
        .length;
    return DecisionAnalytics(
      automatic: automatic,
      manual: decisions.length - automatic,
      estimatedTimeSaved: Duration(minutes: accepted * 2),
      reworkAvoided: accepted,
      acceptanceRate: records.isEmpty ? 0 : accepted / records.length,
      correctionRate: records.isEmpty ? 0 : corrected / records.length,
      averageConfidence: decisions.isEmpty
          ? 0
          : decisions.map((d) => d.confidence).reduce((a, b) => a + b) /
                decisions.length,
    );
  }

  void _record(
    EngineeringDecision decision,
    String action,
    String actor,
    String reason,
  ) => _timeline.add(
    DecisionTimelineEntry(
      sequence: _timeline.length + 1,
      decisionId: decision.id,
      action: action,
      timestamp: DateTime.now(),
      actor: actor,
      reason: reason,
      revision: decision.revision,
    ),
  );
  DecisionPriority _priority(double score) => score >= .9
      ? DecisionPriority.critical
      : score >= .75
      ? DecisionPriority.high
      : score >= .5
      ? DecisionPriority.normal
      : DecisionPriority.low;
  String _justify(
    DecisionRequest request,
    DecisionScore score,
    List<DecisionEvidence> evidence,
  ) =>
      '${request.title}: score '
      '${score.value.toStringAsFixed(3)} sob política ${score.policy.name}; '
      '${evidence.length} evidência(s), impacto: ${request.impact}.';
}
