import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/surface_api.dart';
import '../engine/surface_intelligence_engine.dart';

class SurfaceIntelligenceFELState {
  SurfaceIntelligenceFELState(this.api, this.request);
  final SurfaceIntelligenceApi? api;
  final SurfacePlanningRequest? request;
}

class SurfaceIntelligenceFELCommand implements FELCommand {
  const SurfaceIntelligenceFELCommand(
    this.name,
    this.action,
    this.state,
    this.argumentTypes,
  );
  @override
  final String name;
  final String action;
  final SurfaceIntelligenceFELState state;
  @override
  final List<FELType> argumentTypes;
  SurfaceIntelligenceApi get _api =>
      state.api ??
      (throw StateError(
        'Surface Intelligence is not configured for the active project',
      ));
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    switch (action) {
      case 'plan':
        final request = state.request;
        if (request == null) {
          throw StateError('Surface planning evidence is required');
        }
        value = await _api.plan(request);
      case 'show':
        value = _api.current;
      case 'continuity':
        value = _api.current.candidates
            .map(
              (e) => {
                'candidate': e.id,
                'continuity': e.predictedContinuity.name,
              },
            )
            .toList();
      case 'boundaries':
        value = _api.current.boundaryReport;
      case 'compare':
        value = _api.current.strategies;
      case 'graph':
        value = _api.engine.graph;
      case 'list':
        value = _api.current.candidates;
      case 'explain':
        value = _api.explain(args.first.value as String);
      case 'score':
        final id = args.first.value as String;
        value =
            _api.current.strategies
                .where((e) => e.candidateId == id || e.id == id)
                .firstOrNull ??
            (throw StateError('Surface strategy $id not found'));
      case 'validate':
        value = _api.validate();
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createSurfaceIntelligenceFELCommands({
  SurfaceIntelligenceApi? api,
  SurfacePlanningRequest? request,
}) {
  final state = SurfaceIntelligenceFELState(api, request);
  return [
    SurfaceIntelligenceFELCommand('PLAN SURFACES', 'plan', state, const []),
    SurfaceIntelligenceFELCommand('SHOW SURFACE PLAN', 'show', state, const []),
    SurfaceIntelligenceFELCommand(
      'SHOW CONTINUITY',
      'continuity',
      state,
      const [],
    ),
    SurfaceIntelligenceFELCommand(
      'SHOW BOUNDARIES',
      'boundaries',
      state,
      const [],
    ),
    SurfaceIntelligenceFELCommand(
      'COMPARE SURFACE STRATEGIES',
      'compare',
      state,
      const [],
    ),
    SurfaceIntelligenceFELCommand(
      'SHOW SURFACE GRAPH',
      'graph',
      state,
      const [],
    ),
    SurfaceIntelligenceFELCommand(
      'LIST SURFACE CANDIDATES',
      'list',
      state,
      const [],
    ),
    SurfaceIntelligenceFELCommand('EXPLAIN SURFACE', 'explain', state, const [
      FELType.string,
    ]),
    SurfaceIntelligenceFELCommand('SHOW SURFACE SCORE', 'score', state, const [
      FELType.string,
    ]),
    SurfaceIntelligenceFELCommand(
      'VALIDATE SURFACE PLAN',
      'validate',
      state,
      const [],
    ),
  ];
}
