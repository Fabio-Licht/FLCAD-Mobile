import 'dart:io';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/hybrid_topology/analytics/topology_quality_engine.dart';
import 'package:flcad_mobile/core/hybrid_topology/api/topology_api.dart';
import 'package:flcad_mobile/core/hybrid_topology/compensation/adaptive_compensation_engine.dart';
import 'package:flcad_mobile/core/hybrid_topology/constraints/topology_constraint.dart';
import 'package:flcad_mobile/core/hybrid_topology/engine/hybrid_topology_engine.dart';
import 'package:flcad_mobile/core/hybrid_topology/hybrid/hybrid_object.dart';
import 'package:flcad_mobile/core/hybrid_topology/layers/mesh_layer.dart';
import 'package:flcad_mobile/core/hybrid_topology/morphing/mesh_morph_engine.dart';
import 'package:flcad_mobile/core/hybrid_topology/runtime/topology_runtime.dart';
import 'package:flcad_mobile/core/hybrid_topology/serialization/topology_repository.dart';
import 'package:flcad_mobile/core/hybrid_topology/solver/adaptive_topology_solver.dart';
import 'package:flcad_mobile/core/hybrid_topology/selection/smart_copy.dart';
import 'package:flcad_mobile/core/hybrid_topology/workspace/local_workspace.dart';
import 'package:flcad_mobile/core/smart_regions/selection/triangle_selection.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final mesh = MeshTopology(
  id: 'm',
  vertices: const [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
  triangles: const [Triangle(0, 1, 2)],
);
const asset = GeometryAssetRef(
  'mesh',
  HybridGeometryKind.triangleMesh,
  'Mesh/source.mesh',
  'v1',
);
void main() {
  test('layers compose deltas without changing original mesh', () {
    final before = mesh.vertices.toList(),
        stack = MeshLayerStack([
          MeshLayer(
            id: 'l',
            objectId: 'o',
            name: 'Comp',
            kind: MeshLayerKind.compensation,
            enabled: true,
            locked: false,
            opacity: 1,
            blendMode: LayerBlendMode.additive,
            displacements: const {0: Vec3(0, 0, .1)},
            createdAt: DateTime.utc(2026),
          ),
        ]);
    expect(stack.compose()[0]!.z, .1);
    expect(mesh.vertices, before);
  });
  test('morph constraints freeze and clamp vertices', () {
    final result = const MeshMorphEngine().apply(
      mesh,
      const MorphRequest(
        operation: MorphOperation.push,
        vertexIndices: {0, 1},
        amount: 1,
      ),
      const [
        TopologyConstraint(
          id: 'f',
          type: TopologyConstraintType.frozen,
          vertexIndices: {0},
        ),
        TopologyConstraint(
          id: 'm',
          type: TopologyConstraintType.maxDisplacement,
          vertexIndices: {1},
          parameters: {'maximum': .15},
        ),
      ],
    );
    expect(result.displacements, contains(1));
    expect(result.displacements, isNot(contains(0)));
    expect(result.displacements[1]!.length, closeTo(.15, 1e-6));
  });
  test('compensation and adaptive solver preserve intent', () {
    final request = const AdaptiveCompensationEngine().plan(
      {0, 1},
      const CompensationIntent(
        amount: .25,
        process: 'casting',
        pressureMap: {0: 2},
        thicknessMap: {0: 2},
      ),
      const [],
    );
    expect(request.weights[0], 1);
    expect(
      const AdaptiveTopologySolver()
          .rank(noise: .5, curvature: .2, preserveFeatures: true)
          .first
          .score,
      greaterThan(0),
    );
  });
  test('runtime executes morph in isolate', () async {
    final result = await const IsolateTopologyRuntime().morph(
      mesh,
      const MorphRequest(
        operation: MorphOperation.inflate,
        vertexIndices: {0},
        amount: .1,
      ),
      const [],
    );
    expect(result.displacements, hasLength(1));
  });
  test('AEW and Smart Copy serialize references without geometry buffers', () {
    final workspace = LocalWorkspace(
          id: 'w',
          projectId: 'p',
          objectId: 'o',
          meshAssetId: 'mesh',
          selection: TriangleSelection([1, 2, 3]),
          sourceRegionIds: const ['r'],
          createdAt: DateTime.utc(2026),
        ),
        copy = SmartRegionCopy(
          id: 'c',
          sourceRegionId: 'r',
          meshAssetId: 'mesh',
          selection: TriangleSelection([1, 2, 3]),
          mask: const {1: .8},
          dependencyIds: const ['ref'],
          createdAt: DateTime.utc(2026),
        );
    expect(LocalWorkspace.fromJson(workspace.toJson()).selection.indices, {
      1,
      2,
      3,
    });
    expect(SmartRegionCopy.fromJson(copy.toJson()).mask[1], .8);
    expect(workspace.toJson(), isNot(contains('vertices')));
    expect(copy.toJson(), isNot(contains('triangles')));
  });
  test('FEL registers topology vocabulary', () {
    final r = createNativeCommandRegistry();
    for (final n in [
      'CREATE LOCAL WORKSPACE',
      'COPY REGION',
      'SMART COPY',
      'MORPH',
      'RELAX',
      'SMOOTH',
      'PRESERVE',
      'COMPENSATE',
      'REPAIR TOPOLOGY',
      'REBUILD TOPOLOGY',
      'MERGE TOPOLOGY',
      'SPLIT TOPOLOGY',
      'VALIDATE TOPOLOGY',
    ]) {
      expect(r.find(n), isNotNull);
    }
  });
  test('engine persists Project First non destructive layers', () async {
    final root = await Directory.systemTemp.createTemp('topology_');
    addTearDown(() => root.delete(recursive: true));
    final projects = ProjectRepository(
          storage: LocalStorageService(rootDirectory: root),
        ),
        project = await projects.create(name: 'P', client: 'C'),
        engine = HybridTopologyEngine(
          repository: TopologyRepository(projects: projects),
        ),
        api = TopologyApi(engine: engine),
        object = await api.create(
          projectId: project.id,
          name: 'Hybrid',
          meshAsset: asset,
          mesh: mesh,
        );
    final updated = await api.morph(
      object,
      mesh,
      const MorphRequest(
        operation: MorphOperation.compensation,
        vertexIndices: {0},
        amount: .1,
      ),
    );
    expect(updated.layerIds, hasLength(2));
    expect(const TopologyQualityEngine().analyze(mesh).faceCount, 1);
    final dir = await projects.directoryFor(project.id);
    for (final name in [
      'topology.json',
      'layers.json',
      'workspace.json',
      'constraints.json',
      'morph_history.json',
      'graph.json',
    ]) {
      expect(await File('${dir.path}/Topology/$name').exists(), isTrue);
    }
  });
}
