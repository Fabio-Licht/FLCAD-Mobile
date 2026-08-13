import '../../surface_intelligence/models/surface_models.dart';
import '../engine/surface_generation_engine.dart';
import '../models/surface_generation_models.dart';

abstract class AnalyticSurfaceBuilder {
  const AnalyticSurfaceBuilder(this.engine);
  final SurfaceGenerationEngine engine;
  Future<SurfaceGenerationResult> build(
    SurfaceCandidate candidate,
    Map<String, dynamic> parameters, {
    String? featureId,
  }) => engine.generate(
    SurfaceGenerationRequest(
      candidate: candidate,
      parameters: parameters,
      featureId: featureId,
    ),
  );
}

class PlaneSurfaceBuilder extends AnalyticSurfaceBuilder {
  const PlaneSurfaceBuilder(super.engine);
  Future<SurfaceGenerationResult> fromCandidate(
    SurfaceCandidate candidate, {
    required List<double> origin,
    required List<double> normal,
    double lowerBound = -1,
    double upperBound = 1,
  }) => build(candidate, {
    'origin': origin,
    'normal': normal,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
  });
}

class CylinderSurfaceBuilder extends AnalyticSurfaceBuilder {
  const CylinderSurfaceBuilder(super.engine);
  Future<SurfaceGenerationResult> fromCandidate(
    SurfaceCandidate candidate, {
    required List<double> axisOrigin,
    required List<double> axisDirection,
    required double radius,
    double lowerBound = 0,
    double upperBound = 6.283185307179586,
  }) => build(candidate, {
    'axisOrigin': axisOrigin,
    'axisDirection': axisDirection,
    'radius': radius,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
  });
}

class ConeSurfaceBuilder extends AnalyticSurfaceBuilder {
  const ConeSurfaceBuilder(super.engine);
  Future<SurfaceGenerationResult> fromCandidate(
    SurfaceCandidate candidate, {
    required List<double> apex,
    required List<double> axisDirection,
    required double semiAngle,
    double lowerBound = 0,
    double upperBound = 1,
  }) => build(candidate, {
    'apex': apex,
    'axisDirection': axisDirection,
    'semiAngle': semiAngle,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
  });
}

class SphereSurfaceBuilder extends AnalyticSurfaceBuilder {
  const SphereSurfaceBuilder(super.engine);
  Future<SurfaceGenerationResult> fromCandidate(
    SurfaceCandidate candidate, {
    required List<double> center,
    required double radius,
    double lowerBound = -1.5707963267948966,
    double upperBound = 1.5707963267948966,
  }) => build(candidate, {
    'center': center,
    'radius': radius,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
  });
}
