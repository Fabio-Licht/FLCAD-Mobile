import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_intelligence/models/surface_models.dart';
import '../api/hybrid_surface_api.dart';

class HybridSurfaceFELState {
  HybridSurfaceFELState(this.api, this.source);
  final HybridSurfaceApi? api;
  final SurfacePlan? source;
}

class HybridSurfaceFELCommand implements FELCommand {
  const HybridSurfaceFELCommand(this.name, this.action, this.state);
  @override
  final String name;
  final String action;
  final HybridSurfaceFELState state;
  @override
  List<FELType> get argumentTypes =>
      action == 'explain' ? const [FELType.string] : const [];
  HybridSurfaceApi get _api =>
      state.api ??
      (throw StateError('Hybrid Surface Engine is not configured'));
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    switch (action) {
      case 'build':
        final source = state.source;
        if (source == null) throw StateError('Surface Plan is required');
        value = await _api.build(source);
      case 'show':
        value = _api.current;
      case 'regions':
        value = _api.current.regions;
      case 'continuity':
        value = _api.current.continuity;
      case 'quality':
        value = _api.engine.qualityPredictions;
      case 'compare':
        value = _api.current.strategies;
      case 'patches':
        value = _api.current.patchPlans;
      case 'reconstruction':
        value = _api.current.reconstructionNodes;
      case 'explain':
        value = _api.explain(args.first.value as String);
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

List<FELCommand> createHybridSurfaceFELCommands({
  HybridSurfaceApi? api,
  SurfacePlan? source,
}) {
  final state = HybridSurfaceFELState(api, source);
  return [
    HybridSurfaceFELCommand('BUILD SURFACE NETWORK', 'build', state),
    HybridSurfaceFELCommand('SHOW SURFACE NETWORK', 'show', state),
    HybridSurfaceFELCommand('SHOW HYBRID REGIONS', 'regions', state),
    HybridSurfaceFELCommand('SHOW CONTINUITY GRAPH', 'continuity', state),
    HybridSurfaceFELCommand('SHOW SURFACE QUALITY', 'quality', state),
    HybridSurfaceFELCommand('COMPARE HYBRID STRATEGIES', 'compare', state),
    HybridSurfaceFELCommand('SHOW PATCH PLAN', 'patches', state),
    HybridSurfaceFELCommand(
      'SHOW RECONSTRUCTION NETWORK',
      'reconstruction',
      state,
    ),
    HybridSurfaceFELCommand('EXPLAIN HYBRID STRATEGY', 'explain', state),
    HybridSurfaceFELCommand('VALIDATE SURFACE NETWORK', 'validate', state),
  ];
}
