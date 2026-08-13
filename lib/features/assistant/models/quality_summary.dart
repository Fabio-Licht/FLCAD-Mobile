class QualitySummary {
  const QualitySummary({
    required this.photoQuality,
    required this.coverage,
    required this.scale,
    required this.reconstruction,
    required this.mesh,
    required this.confidence,
  });
  final double photoQuality;
  final double coverage;
  final double scale;
  final double reconstruction;
  final double mesh;
  final double confidence;
  double get overall =>
      photoQuality * .3 +
      coverage * .25 +
      scale * .15 +
      reconstruction * .2 +
      mesh * .1;
  Map<String, dynamic> toJson() => {
    'photoQuality': photoQuality,
    'coverage': coverage,
    'scale': scale,
    'reconstruction': reconstruction,
    'mesh': mesh,
    'confidence': confidence,
    'overall': overall,
  };
}
