import 'package:flcad_mobile/core/smart_regions/analytics/region_analytics_engine.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/smart_regions/models/smart_region.dart';
import 'package:flcad_mobile/core/smart_regions/selection/triangle_selection.dart';
import 'package:flcad_mobile/core/smart_regions/serialization/smart_region_serializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('region JSON is portable and preserves soft weights and attributes', () {
    final mesh = MeshTopology(
      id: 'm',
      vertices: const [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
      triangles: const [Triangle(0, 1, 2)],
    );
    final analysis = const RegionAnalyticsEngine().analyze(
      mesh,
      TriangleSelection([0]),
    );
    final now = DateTime.utc(2026);
    final region = SmartRegion(
      id: 'r',
      projectId: 'p',
      meshId: 'm',
      dna: analysis.dna,
      name: 'Region',
      description: '',
      color: '#fff',
      visible: true,
      locked: false,
      favorite: true,
      confidence: .9,
      layerId: 'inspection',
      tags: const ['hole'],
      metadata: const {'source': 'user'},
      attributes: const {'tolerance': .02},
      createdAt: now,
      updatedAt: now,
      triangleCount: 1,
      vertexCount: 3,
      boundingBox: analysis.bounds,
      statistics: analysis.statistics,
      selection: TriangleSelection([0]),
      weights: const {0: .8},
    );
    final restored = SmartRegionSerializer.fromJson(
      SmartRegionSerializer.toJson(region),
    );
    expect(restored.selection.indices, {0});
    expect(restored.weights[0], .8);
    expect(restored.attributes['tolerance'], .02);
  });
}
