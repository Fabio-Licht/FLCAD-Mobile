import '../models/surface_recognition_models.dart';
import '../regions/recognition_tree.dart';

class RecognitionWorkspace {
  RecognitionWorkspace(SurfaceRecognitionReport report)
    : tree = RecognitionTree(report.classifications),
      confidenceMap = {
        for (final c in report.classifications) c.region.id: c.confidence,
      },
      statistics = report.analytics.toJson(),
      analytics = report.analytics.toJson(),
      advisor = report.advice.map((e) => e.toJson()).toList(),
      timeline = [
        {'event': 'Recognition completed', 'reportId': report.id},
      ];
  final RecognitionTree tree;
  final Map<String, double> confidenceMap;
  final Map<String, dynamic> statistics, analytics;
  final List<Map<String, dynamic>> advisor, timeline;
  void select(String regionId) => tree.select(regionId);
  Map<String, dynamic> get propertyInspector {
    final v = tree.inspectSelected();
    return {
      'Recognition Type': v['type'],
      'Confidence': v['confidence'],
      'Area': v['area'],
      'Triangle Count': v['triangleCount'],
      'Average Normal': v['averageNormal'],
      'Estimated Radius': (v['parameters'] as Map?)?['radius'],
      'Estimated Axis': (v['parameters'] as Map?)?['axis'],
      'Estimated Angle': (v['parameters'] as Map?)?['angle'],
      'Recognition Health': v['health'],
    };
  }
}
