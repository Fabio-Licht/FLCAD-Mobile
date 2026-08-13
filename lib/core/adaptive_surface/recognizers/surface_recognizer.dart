import '../builders/surface_builder.dart';
import '../models/surface_geometry.dart';

class SurfaceRecognition {
  const SurfaceRecognition(this.kind, this.confidence, this.reason);
  final SurfaceKind kind;
  final double confidence;
  final String reason;
}

abstract interface class SurfaceRecognizer {
  Future<List<SurfaceRecognition>> recognize(SurfaceBuildRequest request);
}

class AlphaSurfaceRecognizer implements SurfaceRecognizer {
  const AlphaSurfaceRecognizer();
  @override
  Future<List<SurfaceRecognition>> recognize(SurfaceBuildRequest r) async {
    if (r.samples.length < 3) return const [];
    final a = r.samples[1] - r.samples[0],
        normal = a.cross(r.samples[2] - r.samples[0]).normalized,
        planar =
            r.samples
                .map((p) => (p - r.samples[0]).dot(normal).abs())
                .fold<double>(0, (a, b) => a + b) /
            r.samples.length;
    if (planar < 1e-3) {
      return [
        SurfaceRecognition(
          SurfaceKind.plane,
          (1 - planar).clamp(0, 1),
          'Low point-to-plane deviation',
        ),
      ];
    }
    return const [
      SurfaceRecognition(SurfaceKind.patch, .6, 'No stable primitive detected'),
    ];
  }
}
