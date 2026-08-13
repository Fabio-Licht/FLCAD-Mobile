import '../../adaptive_surface/models/surface_geometry.dart';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../surface_intelligence/models/surface_models.dart';
import '../api/surface_generation_api.dart';
import '../models/surface_generation_models.dart';

class SurfaceGenerationFELState {
  SurfaceGenerationFELState(this.api, this.plan, this.parameters);
  final SurfaceGenerationApi? api;
  final SurfacePlan? plan;
  final Map<String, Map<String, dynamic>> parameters;
}

class SurfaceGenerationFELCommand implements FELCommand {
  const SurfaceGenerationFELCommand(
    this.name,
    this.action,
    this.state,
    this.argumentTypes,
  );
  @override
  final String name;
  final String action;
  final SurfaceGenerationFELState state;
  @override
  final List<FELType> argumentTypes;
  SurfaceGenerationApi get _api =>
      state.api ??
      (throw StateError(
        'Surface Generation is not configured for the active project',
      ));
  SurfaceCandidate _candidate(Object? id, {SurfaceKind? kind}) {
    final plan =
        state.plan ??
        (throw StateError('An approved Surface Plan is required'));
    return plan.candidates
            .where(
              (e) =>
                  (id == null || e.id == id) &&
                  (kind == null || e.kind == kind),
            )
            .firstOrNull ??
        (throw StateError('Approved surface candidate not found'));
  }

  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object? value;
    switch (action) {
      case 'all':
        final plan =
            state.plan ??
            (throw StateError('An approved Surface Plan is required'));
        value = await _api.generateApproved(plan, state.parameters);
      case 'plane':
        final c = _candidate(args.firstOrNull?.value, kind: SurfaceKind.plane);
        value = await _api.engine.generate(
          SurfaceGenerationRequest(
            candidate: c,
            parameters: state.parameters[c.id] ?? const {},
          ),
        );
      case 'cylinder':
        final c = _candidate(
          args.firstOrNull?.value,
          kind: SurfaceKind.cylinder,
        );
        value = await _api.engine.generate(
          SurfaceGenerationRequest(
            candidate: c,
            parameters: state.parameters[c.id] ?? const {},
          ),
        );
      case 'cone':
        final c = _candidate(args.firstOrNull?.value, kind: SurfaceKind.cone);
        value = await _api.engine.generate(
          SurfaceGenerationRequest(
            candidate: c,
            parameters: state.parameters[c.id] ?? const {},
          ),
        );
      case 'sphere':
        final c = _candidate(args.firstOrNull?.value, kind: SurfaceKind.sphere);
        value = await _api.engine.generate(
          SurfaceGenerationRequest(
            candidate: c,
            parameters: state.parameters[c.id] ?? const {},
          ),
        );
      case 'validate':
        final surface =
            _api.engine.registry.find(args.first.value as String) ??
            (throw StateError('Generated surface not found'));
        value = await _api.engine.kernel.validate(surface.handle, const {
          'geometry',
          'continuity',
          'orientation',
          'degeneration',
        });
      case 'heal':
        final surface =
            _api.engine.registry.find(args.first.value as String) ??
            (throw StateError('Generated surface not found'));
        final kernel = _api.engine.kernel;
        if (kernel is! InterchangeGeometryKernelAPI) {
          throw StateError('Active kernel does not support healing');
        }
        value = await kernel.proposeHealing(surface.handle);
      case 'show':
        value = _api.engine.registry.surfaces;
      case 'diagnostics':
        final surface =
            _api.engine.registry.find(args.first.value as String) ??
            (throw StateError('Generated surface not found'));
        value = surface.diagnostics;
      case 'delete':
        await _api.engine.delete(args.first.value as String);
        value = true;
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }
}

List<FELCommand> createSurfaceGenerationFELCommands({
  SurfaceGenerationApi? api,
  SurfacePlan? plan,
  Map<String, Map<String, dynamic>> parameters = const {},
}) {
  final state = SurfaceGenerationFELState(api, plan, parameters);
  return [
    SurfaceGenerationFELCommand('GENERATE SURFACES', 'all', state, const []),
    SurfaceGenerationFELCommand('GENERATE PLANE', 'plane', state, const [
      FELType.string,
    ]),
    SurfaceGenerationFELCommand('GENERATE CYLINDER', 'cylinder', state, const [
      FELType.string,
    ]),
    SurfaceGenerationFELCommand('GENERATE CONE', 'cone', state, const [
      FELType.string,
    ]),
    SurfaceGenerationFELCommand('GENERATE SPHERE', 'sphere', state, const [
      FELType.string,
    ]),
    SurfaceGenerationFELCommand('VALIDATE SURFACE', 'validate', state, const [
      FELType.string,
    ]),
    SurfaceGenerationFELCommand('HEAL SURFACE', 'heal', state, const [
      FELType.string,
    ]),
    SurfaceGenerationFELCommand(
      'SHOW GENERATED SURFACES',
      'show',
      state,
      const [],
    ),
    SurfaceGenerationFELCommand(
      'SHOW SURFACE DIAGNOSTICS',
      'diagnostics',
      state,
      const [FELType.string],
    ),
    SurfaceGenerationFELCommand('DELETE SURFACE', 'delete', state, const [
      FELType.string,
    ]),
  ];
}
