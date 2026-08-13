import 'dart:async';

import '../advisor/workflow_advisor.dart';
import '../engine/guided_workflow_engine.dart';
import '../models/workflow_models.dart';
import '../session/engineering_session.dart';
import '../serialization/workflow_session_repository.dart';

class ProfessionalWorkflowController {
  ProfessionalWorkflowController({
    required this.projectId,
    GuidedWorkflowEngine engine = const GuidedWorkflowEngine(),
    WorkflowAdvisor advisor = const WorkflowAdvisor(),
    WorkflowSessionRepository? sessionRepository,
  }) : _engine = engine,
       _advisor = advisor,
       _sessionRepository = sessionRepository ?? WorkflowSessionRepository(),
       session = EngineeringWorkflowSession(
         id: 'session:${DateTime.now().microsecondsSinceEpoch}',
         projectId: projectId,
       ) {
    _state = _withAdvice(_engine.create(projectId));
  }
  final String projectId;
  final GuidedWorkflowEngine _engine;
  final WorkflowAdvisor _advisor;
  final WorkflowSessionRepository _sessionRepository;
  final EngineeringWorkflowSession session;
  final _changes = StreamController<ProfessionalWorkflowState>.broadcast();
  late ProfessionalWorkflowState _state;
  ProfessionalWorkflowState get state => _state;
  Stream<ProfessionalWorkflowState> get changes => _changes.stream;

  void start(ProfessionalWorkflowStage stage) {
    _emit(_engine.start(_state, stage));
    session.record(SessionEventType.command, 'start:${stage.name}');
    unawaited(_sessionRepository.save(session));
  }

  void complete(
    ProfessionalWorkflowStage stage, {
    ProfessionalArtifact? artifact,
    bool automated = false,
  }) {
    _emit(_engine.complete(_state, stage, artifact: artifact));
    session.record(
      automated ? SessionEventType.automation : SessionEventType.command,
      'complete:${stage.name}',
      accepted: true,
    );
    unawaited(_sessionRepository.save(session));
  }

  void accept(WorkflowRecommendation recommendation) {
    session.record(
      SessionEventType.decision,
      recommendation.id,
      accepted: true,
      metadata: {'confidence': recommendation.decision.confidence},
    );
    unawaited(_sessionRepository.save(session));
    start(recommendation.stage);
  }

  void reject(WorkflowRecommendation recommendation) {
    session.record(
      SessionEventType.decision,
      recommendation.id,
      accepted: false,
    );
    unawaited(_sessionRepository.save(session));
    final timeline = [
      ..._state.timeline,
      EngineeringTimelineEntry(
        sequence: _state.timeline.length + 1,
        timestamp: DateTime.now(),
        type: 'decision',
        title: 'Sugestão adiada',
        description: recommendation.title,
      ),
    ];
    _emit(_state.copyWith(timeline: timeline));
  }

  void selectArtifact(String? id) => _emit(
    _state.copyWith(selectedArtifactId: id, clearSelection: id == null),
  );
  void updateInspection(InspectorSnapshot inspection) {
    final dashboard = WorkflowDashboardSnapshot(
      progress: _state.progress,
      coverage: inspection.coverage,
      regionCount: _state.artifacts
          .where((item) => item.kind == ProfessionalArtifactKind.region)
          .length,
      hypothesisCount: _state.dashboard.hypothesisCount,
      strategy: _state.dashboard.strategy,
      aiStatus: _state.dashboard.aiStatus,
      plannedOperations: _state.dashboard.plannedOperations,
    );
    _emit(_state.copyWith(inspector: inspection, dashboard: dashboard));
  }

  ProfessionalWorkflowState _withAdvice(ProfessionalWorkflowState value) =>
      value.copyWith(recommendations: _advisor.evaluate(value));
  void _emit(ProfessionalWorkflowState value) {
    _state = _withAdvice(value);
    _changes.add(_state);
  }

  Future<void> dispose() => _changes.close();
}
