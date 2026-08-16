import 'package:flcad_mobile/app/engineering_bridge/engineering_bridge.dart';
import 'package:flcad_mobile/app/modeling/modeling.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/professional_recognition/api/professional_recognition_api.dart';
import 'package:flcad_mobile/core/smart_reference/models/smart_reference_models.dart';
import 'package:flcad_mobile/core/smart_regions/analytics/region_analytics_engine.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/smart_regions/models/smart_region.dart';
import 'package:flcad_mobile/core/smart_regions/selection/triangle_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const geometry = KernelMeshGeometry(
    nodes: [0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0],
    triangles: [0, 1, 2, 0, 2, 3],
  );
  const selection = BridgeSelection(
    id: 'selection-1',
    kind: BridgeSelectionKind.meshRegion,
    geometry: geometry,
    triangleIndices: {0, 1},
  );

  test('kernel mesh hit testing returns the nearest real triangle', () {
    final hit = const MeshHitTesting().hit(
      selection,
      const MeshRay(Vector3(.75, .25, 1), Vector3(0, 0, -1)),
    );
    expect(hit, isNotNull);
    expect(hit!.triangleIndex, 0);
    expect(hit.point.z, closeTo(0, 1e-12));
    expect(hit.distance, closeTo(1, 1e-12));
  });

  test('screen position is exactly unprojected into a camera ray', () {
    final ray = const CameraPicking().ray(
      screenX: 50,
      screenY: 25,
      camera: const CameraPickingContext(
        viewportWidth: 100,
        viewportHeight: 100,
        inverseViewProjection: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
      ),
    );
    expect(ray.origin.x, closeTo(0, 1e-12));
    expect(ray.origin.y, closeTo(.5, 1e-12));
    expect(ray.origin.z, closeTo(-1, 1e-12));
    expect(ray.direction.z, closeTo(1, 1e-12));
  });

  test(
    'professional picking uses BVH candidates before triangle intersection',
    () {
      const indexedGeometry = KernelMeshGeometry(
        nodes: [
          -0.5,
          -0.5,
          0,
          0.5,
          -0.5,
          0,
          0,
          0.5,
          0,
          10,
          10,
          0,
          11,
          10,
          0,
          10,
          11,
          0,
        ],
        triangles: [0, 1, 2, 3, 4, 5],
      );
      const mesh = BridgeSelection(
        id: 'indexed',
        kind: BridgeSelectionKind.meshRegion,
        geometry: indexedGeometry,
        triangleIndices: {0, 1},
      );
      final bvh = MeshBvh(indexedGeometry, leafSize: 1);
      final hit = const ProfessionalPickingPipeline().pick(
        screenX: 50,
        screenY: 50,
        cameraContext: const CameraPickingContext(
          viewportWidth: 100,
          viewportHeight: 100,
          inverseViewProjection: [
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
          ],
        ),
        mesh: mesh,
        spatialIndex: bvh,
      );
      expect(bvh.query(const MeshRay(Vector3(0, 0, -1), Vector3(0, 0, 1))), {
        0,
      });
      expect(hit?.triangleIndex, 0);
    },
  );

  test(
    'region builder preserves bounds area normals triangles and connectivity',
    () {
      final region = const MeshRegionBuilder().build(
        meshId: 'mesh-1',
        selection: selection,
      );
      expect(region.triangleIndices, [0, 1]);
      expect(region.vertexIndices, [0, 1, 2, 3]);
      expect(region.area, closeTo(1, 1e-12));
      expect(region.normals, hasLength(2));
      expect(region.connectivity[0], {1});
      expect(region.bounds.toJson(), {
        'min': [0.0, 0.0, 0.0],
        'max': [1.0, 1.0, 0.0],
      });
      expect(region.fingerprint, 'mesh-1:0,1:0,1,2,3');
    },
  );

  test(
    'disconnected triangles are rejected instead of forming an artificial region',
    () {
      const disconnected = KernelMeshGeometry(
        nodes: [0, 0, 0, 1, 0, 0, 0, 1, 0, 10, 10, 0, 11, 10, 0, 10, 11, 0],
        triangles: [0, 1, 2, 3, 4, 5],
      );
      expect(
        () => const MeshRegionBuilder().build(
          meshId: 'mesh',
          selection: const BridgeSelection(
            id: 'disconnected',
            kind: BridgeSelectionKind.meshRegion,
            geometry: disconnected,
            triangleIndices: {0, 1},
          ),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'recognition bridge performs a lossless official context translation',
    () {
      final region = const MeshRegionBuilder().build(
        meshId: 'mesh-1',
        selection: selection,
      );
      final bridge = RecognitionBridge(ProfessionalRecognitionApi());
      final context = bridge.contextFor(
        BridgeContext(
          projectId: 'project-1',
          meshId: 'mesh-1',
          meshFingerprint: 'kernel-fingerprint',
          userConfirmed: false,
          region: region,
        ),
      );
      expect(context.observation.points, region.points);
      expect(context.observation.normals, region.normals);
      expect(context.observation.adjacency, region.connectivity);
      expect(context.observation.regionFingerprint, region.fingerprint);
    },
  );

  test(
    'synchronization and passive runtime do not execute engineering decisions',
    () async {
      final viewport = ModelingViewportController();
      final viewportSync = BridgeViewportSync(viewport);
      const selected = ModelingSelection(
        id: 'r',
        name: 'Region',
        type: ModelingSelectionType.meshRegion,
      );
      viewportSync.selected(selected);
      expect(viewport.selection.single.id, 'r');
      final explorer = BridgeExplorerState();
      BridgeExplorerSync(explorer).created('r', selected);
      expect(explorer.entities['r'], same(selected));
      final assistant = BridgeAssistantSync();
      assistant.publish(
        const BridgeAssistantMessage(
          title: 'Plane hypothesis',
          evidence: ['region:r'],
          confidence: .98,
          alternatives: ['cylinder'],
          justification: 'Certified recognition evidence.',
        ),
      );
      expect(assistant.messages, hasLength(1));
      final runtime = EngineeringBridgeRuntime();
      await expectLater(runtime.execute(() async => 1), throwsStateError);
      await runtime.initialize();
      expect(await runtime.execute(() async => 7), 7);
      viewport.dispose();
    },
  );

  test('Smart Reference mapper creates a region-backed plane recipe only', () {
    final mesh = MeshTopology(
      id: 'mesh-1',
      vertices: const [Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0)],
      triangles: const [Triangle(0, 1, 2)],
    );
    final analysis = const RegionAnalyticsEngine().analyze(
      mesh,
      TriangleSelection([0]),
    );
    final now = DateTime.utc(2026);
    final region = SmartRegion(
      id: 'region-1',
      projectId: 'project',
      meshId: mesh.id,
      dna: analysis.dna,
      name: 'Region',
      description: '',
      color: '#fff',
      visible: true,
      locked: false,
      favorite: false,
      confidence: .95,
      layerId: 'structural',
      tags: const [],
      metadata: const {},
      attributes: const {},
      createdAt: now,
      updatedAt: now,
      triangleCount: 1,
      vertexCount: 3,
      boundingBox: analysis.bounds,
      statistics: analysis.statistics,
      selection: TriangleSelection([0]),
    );
    final candidate = ReferenceCandidate(
      id: 'candidate-plane',
      type: ReferenceCandidateType.basePlane,
      scores: const ReferenceScores(
        geometricScore: 1,
        topologyScore: 1,
        manufacturingScore: 1,
        functionalScore: 1,
        symmetryScore: 1,
        featureScore: 1,
        contextScore: 1,
        historyScore: 1,
        overallConfidence: .95,
      ),
      evidence: [
        ReferenceEvidence(
          id: 'e',
          source: 'recognition',
          description: 'plane fit',
          primitiveIds: const ['plane-1'],
          featureIds: const [],
          score: .95,
        ),
      ],
      justification: 'Recognized plane',
      primitiveIds: const ['plane-1'],
      featureIds: const [],
      topologicalRelationships: const [],
      discardedHypotheses: const ['axis'],
      canonical: const CanonicalReferenceSuggestion(
        measuredReference: 'plane',
        canonicalReference: 'XY',
        angularErrorDegrees: 0,
        confidence: .95,
        justification: 'canonical',
        reasons: ['normal'],
      ),
    );
    final recipe = const SmartReferenceRecipeMapper().map(
      candidate: candidate,
      region: region,
      approvedParameters: const {'tolerance': .02},
    );
    expect(recipe.builderId, 'plane');
    expect(recipe.sourceIds, ['region-1']);
    expect(recipe.parameters, {'method': 'region', 'tolerance': .02});
  });

  test('CAD scene graph updates entities incrementally by stable identity', () {
    final scene = CadSceneGraph();
    const plane = CadSceneEntity(
      id: 'plane-1',
      kind: CadSceneEntityKind.plane,
      geometry: {'type': 'plane'},
      transparent: true,
    );
    scene.upsert(plane);
    scene.select({'plane-1'});
    expect(scene.find('plane-1')!.selected, isTrue);
    expect(scene.find('plane-1')!.transparent, isTrue);
    scene.remove('plane-1');
    expect(scene.find('plane-1'), isNull);
  });
}
