import '../models/validation_models.dart';

enum HeatBand { negative, insideTolerance, positive, warning, critical }

class HeatMapPoint {
  const HeatMapPoint(
    this.regionId,
    this.deviation,
    this.confidence,
    this.band,
    this.color,
  );
  final String regionId, color;
  final double deviation, confidence;
  final HeatBand band;
}

class HeatMapPreview {
  const HeatMapPreview({
    required this.sessionId,
    required this.points,
    required this.colorScale,
    required this.criticalRegions,
    required this.warningRegions,
  });
  final String sessionId, colorScale;
  final List<HeatMapPoint> points;
  final List<String> criticalRegions, warningRegions;
}

class HeatMapEngine {
  const HeatMapEngine();
  HeatMapPreview create(LiveValidationSession session) {
    final points = [
      for (final s in session.samples.values) _point(s, session.parameters),
    ];
    return HeatMapPreview(
      sessionId: session.id,
      points: points,
      colorScale: session.parameters.colorScale,
      criticalRegions: [
        for (final p in points)
          if (p.band == HeatBand.critical) p.regionId,
      ],
      warningRegions: [
        for (final p in points)
          if (p.band == HeatBand.warning) p.regionId,
      ],
    );
  }

  HeatMapPoint _point(DeviationSample sample, ValidationParameters p) {
    final absolute = sample.deviation.abs();
    final band = absolute >= p.criticalThreshold
        ? HeatBand.critical
        : absolute >= p.warningThreshold
        ? HeatBand.warning
        : absolute <= p.tolerance
        ? HeatBand.insideTolerance
        : sample.deviation < 0
        ? HeatBand.negative
        : HeatBand.positive;
    final color = switch (band) {
      HeatBand.negative => 'blue',
      HeatBand.insideTolerance => 'green',
      HeatBand.positive => 'yellow',
      HeatBand.warning => 'orange',
      HeatBand.critical => 'red',
    };
    return HeatMapPoint(
      sample.regionId,
      sample.deviation,
      sample.confidence,
      band,
      color,
    );
  }
}
