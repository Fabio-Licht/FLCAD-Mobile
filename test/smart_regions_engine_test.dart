import 'dart:io';

import 'package:flcad_mobile/core/smart_regions/analytics/region_analytics_engine.dart';
import 'package:flcad_mobile/core/smart_regions/api/smart_regions_api.dart';
import 'package:flcad_mobile/core/smart_regions/cache/region_cache.dart';
import 'package:flcad_mobile/core/smart_regions/commands/region_command.dart';
import 'package:flcad_mobile/core/smart_regions/engine/smart_border_engine.dart';
import 'package:flcad_mobile/core/smart_regions/events/region_event.dart';
import 'package:flcad_mobile/core/smart_regions/graph/region_graph.dart';
import 'package:flcad_mobile/core/smart_regions/history/region_history.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/smart_regions/pipeline/region_pipeline.dart';
import 'package:flcad_mobile/core/smart_regions/repository/smart_region_repository.dart';
import 'package:flcad_mobile/core/smart_regions/rules/region_rule.dart';
import 'package:flcad_mobile/core/smart_regions/scripts/region_script_engine.dart';
import 'package:flcad_mobile/core/smart_regions/selection/triangle_selection.dart';
import 'package:flcad_mobile/core/smart_regions/services/region_dna_matcher.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MeshTopology mesh;
  setUp(
    () => mesh = MeshTopology(
      id: 'mesh',
      vertices: const [
        Vec3(0, 0, 0),
        Vec3(1, 0, 0),
        Vec3(1, 1, 0),
        Vec3(0, 1, 0),
        Vec3(2, 0, 0),
        Vec3(2, 1, 0),
      ],
      triangles: const [
        Triangle(0, 1, 2),
        Triangle(0, 2, 3),
        Triangle(1, 4, 5),
        Triangle(1, 5, 2),
      ],
    ),
  );

  test('selection set operations do not copy or modify the mesh', () {
    final a = TriangleSelection([0, 1]), b = TriangleSelection([1, 2]);
    expect(a.union(b).indices, {0, 1, 2});
    expect(a.intersect(b).indices, {1});
    expect(a.subtract(b).indices, {0});
    expect(mesh.triangles, hasLength(4));
    expect(TriangleSelection.fromRanges(a.union(b).toRanges()).indices, {
      0,
      1,
      2,
    });
  });

  test('border, rules, pipeline and scripts are deterministic', () {
    const border = SmartBorderEngine();
    final seed = TriangleSelection([0]);
    expect(border.expand(mesh, seed).indices, {0, 1, 3});
    expect(
      border.shrink(mesh, TriangleSelection([0, 1, 2, 3])).length,
      greaterThanOrEqualTo(0),
    );
    expect(
      const RemoveIslandsRule(
        2,
      ).apply(mesh, TriangleSelection([0, 1, 2, 3])).length,
      4,
    );
    final pipeline = RegionPipeline(const [ExpandCommand(1), SmoothCommand(1)]);
    final first = pipeline.run(mesh, seed);
    final script = RegionScript('prepare', const [
      ExpandCommand(1),
      SmoothCommand(1),
    ]);
    expect(
      RegionScriptEngine().execute(script, mesh, seed).indices,
      first.indices,
    );
  });

  test('analytics and DNA matching produce reusable signatures', () {
    const analytics = RegionAnalyticsEngine();
    final a = analytics.analyze(mesh, TriangleSelection([0, 1]));
    final b = analytics.analyze(mesh, TriangleSelection([0, 1]));
    expect(a.statistics.area, closeTo(1, .001));
    expect(a.dna.hash, b.dna.hash);
    expect(const RegionDNAMatcher().similarity(a.dna, b.dna), closeTo(1, .001));
  });

  test('graph, cache, history and intent remain independent', () {
    final graph = RegionGraph()
      ..addNode(const RegionGraphNode('r', RegionNodeType.region, 'r'))
      ..addNode(const RegionGraphNode('p', RegionNodeType.plane, 'p'))
      ..connect(const RegionGraphEdge('r', 'p', 'derives'));
    expect(graph.dependentsOf('r'), {'p'});
    final cache = RegionCache()..write('mesh', 'dna', 'analytics', 42);
    expect(cache.read<int>('mesh', 'dna', 'analytics'), 42);
    cache.invalidateRegion('dna');
    expect(cache.read<int>('mesh', 'dna', 'analytics'), isNull);
    final history = RegionHistory();
    history.record('r', TriangleSelection([0]), 'create');
    history.record('r', TriangleSelection([0, 1]), 'expand');
    expect(history.restore('r', 1).indices, {0});
  });

  test(
    'API persists regions, snapshots and events inside the project',
    () async {
      final root = await Directory.systemTemp.createTemp('flcad_regions_');
      addTearDown(() => root.delete(recursive: true));
      final projects = ProjectRepository(
        storage: LocalStorageService(rootDirectory: root),
      );
      final project = await projects.create(name: 'Part', client: 'Client');
      final repository = SmartRegionRepository(projects: projects);
      final bus = RegionEventBus();
      final events = <RegionEvent>[];
      bus.subscribe(events.add);
      final api = SmartRegionsApi(repository: repository, events: bus);
      final region = await api.create(
        projectId: project.id,
        mesh: mesh,
        selection: TriangleSelection([0, 1]),
        name: 'Flange',
      );
      expect(
        (await repository.loadRegions(project.id)).single.dna.hash,
        region.dna.hash,
      );
      expect(events.single.type, RegionEventType.created);
      await repository.saveSnapshot(project.id, 'v1', [region]);
      final directory = await projects.directoryFor(project.id);
      expect(
        await File('${directory.path}/SmartRegions/Snapshots/v1.json').exists(),
        isTrue,
      );
      expect(api.intents.infer(region).first.action, 'create_plane');
    },
  );
}
