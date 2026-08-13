import '../../smart_regions/models/geometry.dart';
import '../../smart_regions/selection/triangle_selection.dart';
import '../../smart_regions/engine/smart_border_engine.dart';

class BorderAnalysis {
  const BorderAnalysis({
    required this.selection,
    required this.confidence,
    required this.roughness,
    required this.continuity,
    required this.recommendation,
  });
  final TriangleSelection selection;
  final double confidence, roughness, continuity;
  final String recommendation;
}

class SmartBorderEngineV2 {
  const SmartBorderEngineV2();
  BorderAnalysis analyze(MeshTopology mesh, TriangleSelection selection) {
    if (selection.length == 0) {
      return BorderAnalysis(
        selection: selection,
        confidence: 0,
        roughness: 1,
        continuity: 0,
        recommendation: 'select-region',
      );
    }
    final normals = selection.indices.map(mesh.triangleNormal).toList(),
        average = normals
            .fold<Vec3>(const Vec3(0, 0, 0), (a, b) => a + b)
            .normalized,
        roughness =
            normals
                .map((n) => 1 - n.dot(average).abs())
                .fold<double>(0, (a, b) => a + b) /
            normals.length,
        confidence = (1 - roughness).clamp(0, 1).toDouble();
    return BorderAnalysis(
      selection: selection,
      confidence: confidence,
      roughness: roughness,
      continuity: confidence,
      recommendation: roughness > .2 ? 'shrink-smooth' : 'preserve',
    );
  }

  TriangleSelection prepare(
    MeshTopology mesh,
    TriangleSelection selection, {
    int shrink = 0,
    int expand = 0,
    int smooth = 0,
  }) {
    var result = selection;
    const border = SmartBorderEngine();
    if (shrink > 0) result = border.shrink(mesh, result, rings: shrink);
    if (expand > 0) result = border.expand(mesh, result, rings: expand);
    if (smooth > 0) result = border.smooth(mesh, result, iterations: smooth);
    return result;
  }
}
