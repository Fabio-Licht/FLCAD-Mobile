import '../../adaptive_surface/models/surface_geometry.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../models/surface_generation_models.dart';

class SurfaceGenerationValidator {
  const SurfaceGenerationValidator();
  List<GeometryDiagnostic> validate(SurfaceGenerationRequest request) {
    final p = request.parameters, result = <GeometryDiagnostic>[];
    void required(String key) {
      if (!p.containsKey(key)) {
        result.add(
          GeometryDiagnostic(
            code: 'missing-$key',
            message: 'Required parameter $key is missing',
            severity: 'error',
          ),
        );
      }
    }

    switch (request.candidate.kind) {
      case SurfaceKind.plane:
        required('origin');
        required('normal');
      case SurfaceKind.cylinder:
        required('axisOrigin');
        required('axisDirection');
        required('radius');
      case SurfaceKind.cone:
        required('apex');
        required('axisDirection');
        required('semiAngle');
      case SurfaceKind.sphere:
        required('center');
        required('radius');
      default:
        result.add(
          GeometryDiagnostic(
            code: 'unsupported-surface-kind',
            message: '${request.candidate.kind.name} is outside G-005B',
            severity: 'error',
          ),
        );
    }
    for (final key in ['radius', 'tolerance']) {
      final value = p[key];
      if (value is num && value <= 0) {
        result.add(
          GeometryDiagnostic(
            code: 'invalid-$key',
            message: '$key must be greater than zero',
            severity: 'error',
          ),
        );
      }
    }
    final lower = p['lowerBound'], upper = p['upperBound'];
    if (lower is num && upper is num && lower >= upper) {
      result.add(
        const GeometryDiagnostic(
          code: 'invalid-bounds',
          message: 'Lower bound must be smaller than upper bound',
          severity: 'error',
        ),
      );
    }
    if (request.candidate.regionIds.isEmpty) {
      result.add(
        const GeometryDiagnostic(
          code: 'invalid-region',
          message: 'Candidate must reference at least one region',
          severity: 'error',
        ),
      );
    }
    if (request.candidate.confidence <= 0) {
      result.add(
        const GeometryDiagnostic(
          code: 'invalid-confidence',
          message: 'Candidate confidence must be positive',
          severity: 'error',
        ),
      );
    }
    if (request.tolerance <= 0) {
      result.add(
        const GeometryDiagnostic(
          code: 'invalid-tolerance',
          message: 'Tolerance must be greater than zero',
          severity: 'error',
        ),
      );
    }
    return result;
  }
}
