// ignore_for_file: curly_braces_in_flow_control_structures

import '../../../core/sketch_engine/models/sketch_models.dart';
import '../../../core/surface_generation/api/surface_generation_api.dart';
import '../../../core/surface_generation/models/surface_generation_models.dart';
import '../../../core/surface_intelligence/models/surface_models.dart';
import '../contracts/bridge_context.dart';
import '../contracts/bridge_validation.dart';

class SurfaceBridge {
  const SurfaceBridge(this.api, {this.validation = const BridgeValidation()});
  final SurfaceGenerationApi api;
  final BridgeValidation validation;
  Future<List<SurfaceGenerationResult>> generateApproved({
    required BridgeContext context,
    required Sketch sketch,
    required SurfacePlan plan,
    required Map<String, Map<String, dynamic>> parameters,
  }) {
    validation.requireConfirmation(context);
    if (sketch.entityIds.isEmpty)
      throw StateError(
        'A valid non-empty sketch is required for surface generation.',
      );
    if (plan.selectedStrategyIds.isEmpty)
      throw StateError('An approved SurfacePlan strategy is required.');
    return api.generateApproved(plan, parameters);
  }
}
