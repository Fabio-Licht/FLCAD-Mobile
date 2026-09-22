import '../cad_kernel/api/geometry_kernel_api.dart';
import '../cad_kernel/models/kernel_models.dart';

/// Non-persistent request for the OCCT multi-loop Extrude route.
///
/// The operation deliberately owns no document or viewport state. A future
/// Professional Solids controller may use it for preview and Apply while the
/// adapter resolves [profiles] to its live native tokens.
class MultiProfileExtrudeRequest {
  const MultiProfileExtrudeRequest({
    required this.profiles,
    required this.direction,
    required this.solidOutput,
    this.draftAngleDegrees = 0,
    this.symmetric = false,
    this.tolerance = 1e-7,
  });

  final List<ShapeHandle> profiles;
  final List<double> direction;
  final bool solidOutput;
  final double draftAngleDegrees;
  final bool symmetric;
  final double tolerance;

  void validate() {
    if (profiles.length < 2) {
      throw ArgumentError('Extrude Multi requires at least two profiles.');
    }
    final ids = profiles.map((profile) => profile.persistentId).toList();
    if (ids.any((id) => id.isEmpty) || ids.toSet().length != ids.length) {
      throw ArgumentError('Extrude Multi profiles must be unique and valid.');
    }
    final hasOpen = profiles.any(
      (profile) => profile.metadata['closed'] == false,
    );
    final hasClosed = profiles.any(
      (profile) => profile.metadata['closed'] == true,
    );
    if (solidOutput && hasOpen) {
      throw ArgumentError(
        'Extrude Multi solid output requires closed profiles.',
      );
    }
    if (!solidOutput && hasOpen && hasClosed) {
      throw ArgumentError('Extrude Multi cannot mix open and closed profiles.');
    }
    if (direction.length != 3 ||
        direction.any((value) => !value.isFinite) ||
        direction.every((value) => value.abs() <= 1e-12)) {
      throw ArgumentError(
        'Extrude Multi direction must be finite and non-zero.',
      );
    }
    if (!draftAngleDegrees.isFinite || draftAngleDegrees.abs() >= 89) {
      throw ArgumentError(
        'Extrude Multi Draft must be between -89 and 89 degrees.',
      );
    }
    if (!tolerance.isFinite || tolerance <= 0) {
      throw ArgumentError(
        'Extrude Multi tolerance must be finite and positive.',
      );
    }
  }

  Map<String, dynamic> toKernelParameters() {
    validate();
    return {
      'inputs': profiles,
      'direction': direction,
      'output': solidOutput ? 'solid' : 'surface',
      'draftAngleDegrees': draftAngleDegrees,
      'symmetric': symmetric,
      'tolerance': tolerance,
    };
  }
}

class MultiProfileExtrudeRuntime {
  const MultiProfileExtrudeRuntime();

  Future<ShapeHandle> create(
    GeometryKernelAPI kernel,
    MultiProfileExtrudeRequest request, {
    required String persistentId,
    required KernelTransaction transaction,
  }) {
    request.validate();
    return kernel.create(
      'EXTRUDE MULTI',
      request.toKernelParameters(),
      persistentId: persistentId,
      expectedType: CADShapeType.compound,
      transaction: transaction,
    );
  }
}
