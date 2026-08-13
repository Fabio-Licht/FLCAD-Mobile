import 'package:flcad_mobile/core/reference_engine/analytics/reference_analytics_engine.dart';
import 'package:flcad_mobile/core/reference_engine/builders/axis_point_curve_builders.dart';
import 'package:flcad_mobile/core/reference_engine/builders/plane_builder.dart';
import 'package:flcad_mobile/core/reference_engine/builders/reference_builder.dart';
import 'package:flcad_mobile/core/reference_engine/cache/reference_cache.dart';
import 'package:flcad_mobile/core/reference_engine/constraints/reference_constraint.dart';
import 'package:flcad_mobile/core/reference_engine/events/reference_event.dart';
import 'package:flcad_mobile/core/reference_engine/graph/reference_graph.dart';
import 'package:flcad_mobile/core/reference_engine/history/reference_history.dart';
import 'package:flcad_mobile/core/reference_engine/models/reference_entity.dart';
import 'package:flcad_mobile/core/reference_engine/models/reference_geometry.dart';
import 'package:flcad_mobile/core/reference_engine/runtime/reference_runtime.dart';
import 'package:flcad_mobile/core/reference_engine/serialization/reference_serializer.dart';
import 'package:flcad_mobile/core/reference_engine/validators/reference_constraint_validator.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flutter_test/flutter_test.dart';

const emptyContext = ReferenceBuildContext(
  projectId: 'p',
  meshes: {},
  regions: {},
  references: {},
);

ReferenceEntity entity(String id, ReferenceGeometry geometry) {
  final now = DateTime.utc(2026);
  return ReferenceEntity(
    id: id,
    projectId: 'p',
    name: id,
    geometry: geometry,
    mode: ReferenceMode.live,
    status: ReferenceStatus.valid,
    dna: createReferenceDNA(geometry.type, id, geometry),
    analytics: const ReferenceAnalytics(
      precision: 1,
      rmsError: 0,
      maxDeviation: 0,
      confidence: 1,
      fitQuality: 1,
      areaUsed: 0,
      coverage: 1,
      pointCount: 1,
    ),
    recipe: const ReferenceRecipe('test', {}, []),
    version: 1,
    createdAt: now,
    updatedAt: now,
    dependencies: const [],
    metadata: const {},
  );
}

void main() {
  group('reference builders', () {
    test('build plane from three points', () async {
      final result = await PlaneBuilder().build(
        emptyContext,
        const ReferenceRecipe('plane', {
          'method': 'threePoints',
          'points': [
            [0, 0, 0],
            [1, 0, 0],
            [0, 1, 0],
          ],
        }, []),
      );
      expect((result.geometry as PlaneGeometry).normal.z, closeTo(1, 1e-9));
    });

    test('build axis, point, curve and coordinate system', () async {
      final axis = await AxisBuilder().build(
        emptyContext,
        const ReferenceRecipe('axis', {
          'method': 'twoPoints',
          'points': [
            [0, 0, 0],
            [0, 0, 2],
          ],
        }, []),
      );
      final point = await PointBuilder().build(
        emptyContext,
        const ReferenceRecipe('point', {
          'method': 'explicit',
          'point': [1, 2, 3],
        }, []),
      );
      final curve = await CurveBuilder().build(
        emptyContext,
        const ReferenceRecipe('curve', {
          'points': [
            [0, 0, 0],
            [1, 1, 0],
          ],
        }, []),
      );
      final ucs = await CoordinateSystemBuilder().build(
        emptyContext,
        const ReferenceRecipe('coordinateSystem', {}, []),
      );
      expect((axis.geometry as AxisGeometry).direction.z, 1);
      expect((point.geometry as PointGeometry).position.y, 2);
      expect((curve.geometry as CurveGeometry).points, hasLength(2));
      expect((ucs.geometry as CoordinateSystemGeometry).zAxis.z, 1);
    });
  });

  test('analytics reports RMS and confidence', () {
    final value = const ReferenceAnalyticsEngine().evaluate(
      const PlaneGeometry(Vec3(0, 0, 0), Vec3(0, 0, 1)),
      const [Vec3(0, 0, 1), Vec3(0, 0, -1)],
    );
    expect(value.rmsError, 1);
    expect(value.pointCount, 2);
    expect(value.confidence, inInclusiveRange(0, 1));
  });

  test('constraints validate relationships', () {
    final refs = {
      'a': entity('a', const AxisGeometry(Vec3(0, 0, 0), Vec3(1, 0, 0))),
      'b': entity('b', const AxisGeometry(Vec3(0, 1, 0), Vec3(1, 0, 0))),
    };
    final result = const ReferenceConstraintValidator().validate(
      const ReferenceConstraint(
        id: 'c',
        type: ReferenceConstraintType.parallel,
        referenceIds: ['a', 'b'],
        parameters: {},
        enabled: true,
      ),
      refs,
    );
    expect(result.satisfied, isTrue);
  });

  test('graph, history, cache and events remain independent', () {
    final graph = ReferenceGraph()
      ..add('source')
      ..add('reference')
      ..connect('source', 'reference', 'derives');
    expect(graph.dependents('source'), {'reference'});
    expect(ReferenceGraph.fromJson(graph.toJson()).dependents('source'), {
      'reference',
    });
    final reference = entity('reference', const PointGeometry(Vec3(0, 0, 0)));
    final history = ReferenceHistory()..record(reference, 'created');
    expect(history.restore('reference', 1).id, 'reference');
    final cache = ReferenceCache();
    final result = ReferenceBuildResult(
      reference.geometry,
      reference.analytics,
      'fp',
    );
    cache.write('point', 'fp', result);
    expect(cache.read('point', 'fp'), same(result));
    final bus = ReferenceEventBus();
    ReferenceEvent? received;
    bus.subscribe((event) => received = event);
    bus.publish(
      ReferenceEvent(
        ReferenceEventType.created,
        reference.id,
        'p',
        DateTime.now(),
        const {},
      ),
    );
    expect(received?.type, ReferenceEventType.created);
  });

  test('serialization round trip preserves shared model', () {
    final source = entity(
      'plane',
      const PlaneGeometry(Vec3(1, 2, 3), Vec3(0, 0, 1)),
    );
    final restored = ReferenceSerializer.fromJson(
      ReferenceSerializer.toJson(source),
    );
    expect(restored.id, source.id);
    expect(restored.geometry, isA<PlaneGeometry>());
    expect(restored.dna.hash, source.dna.hash);
  });

  test('heavy analytics can run in an isolate', () async {
    final value = await const IsolateReferenceRuntime().analyze(
      const PointGeometry(Vec3(0, 0, 0)),
      const [Vec3(3, 4, 0)],
    );
    expect(value.rmsError, 5);
  });
}
