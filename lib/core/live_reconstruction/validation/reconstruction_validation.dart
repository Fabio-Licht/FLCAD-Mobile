import '../models/live_reconstruction_models.dart';

class ReconstructionValidator {
  const ReconstructionValidator();
  ReconstructionValidation validate(LiveReconstruction value) {
    final affected = value.preview?.affected;
    final errors = <String>[
      if (value.operation.validation?.valid != true)
        'Surface operation validation is not approved',
      if (affected == null || affected.patches.isEmpty)
        'No affected patch was calculated',
      if (affected != null &&
          affected.all.any((id) => !value.graph.nodes.containsKey(id)))
        'Affected object is absent from the dependency graph',
      if (value.preview?.originalSurfaceIds[value.operation.targetPatch.id] !=
          value.operation.targetSurface.persistentId)
        'Preview baseline does not match the operation target',
    ];
    return ReconstructionValidation(errors.isEmpty, List.unmodifiable(errors));
  }
}
