import 'dart:io';
import 'dart:convert';

import 'package:flcad_mobile/app/cad_viewport/camera/cad_camera_controller.dart';
import 'package:flcad_mobile/app/cad_viewport/professional_cad_viewport_widget.dart';
import 'package:flcad_mobile/app/cad_viewport/rendering/mesh_scene_adapter.dart';
import 'package:flcad_mobile/app/cad_viewport/scene/cad_scene_graph.dart';
import 'package:flcad_mobile/app/cad_viewport/selection/viewport_picking_controller.dart';
import 'package:flcad_mobile/app/commands/desktop_command_coordinator.dart';
import 'package:flcad_mobile/app/desktop/desktop_cad_controller.dart';
import 'package:flcad_mobile/app/engineering_bridge/operational_reverse_engineering_controller.dart';
import 'package:flcad_mobile/app/engineering_bridge/contracts/bridge_selection.dart';
import 'package:flcad_mobile/app/engineering_bridge/contracts/bridge_context.dart';
import 'package:flcad_mobile/core/cad_kernel/io/kernel_io_models.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flcad_mobile/core/cad_kernel/models/kernel_models.dart';
import 'package:flcad_mobile/core/geometric_kernel/geometry/vectors.dart';
import 'package:flcad_mobile/core/import_export/api/import_export_api.dart';
import 'package:flcad_mobile/core/professional_recognition/api/professional_recognition_api.dart';
import 'package:flcad_mobile/core/reference_engine/models/reference_entity.dart';
import 'package:flcad_mobile/core/reference_engine/models/reference_geometry.dart';
import 'package:flcad_mobile/core/reference_engine/api/reference_api.dart';
import 'package:flcad_mobile/core/reference_engine/engine/reference_engine.dart';
import 'package:flcad_mobile/core/reference_engine/repository/reference_repository.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flcad_mobile/features/projects/domain/project_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mesh = KernelMeshGeometry(
    nodes: [-1, -1, 0, 1, -1, 0, 0, 1, 0],
    triangles: [0, 1, 2],
  );
  const bounds = KernelBounds(-1, -1, 0, 1, 1, 0);

  test('camera exposes stable invertible matrices and both projections', () {
    final camera = CadCameraController();
    camera.resize(800, 600);
    camera.fit(const Vector3(-1, -1, -1), const Vector3(1, 1, 1));
    final point = const Vector3(.25, -.4, .1);
    final projected = camera.viewProjectionMatrix.transformPoint(point);
    final restored = camera.inverseViewProjectionMatrix.transformPoint(
      projected,
    );
    expect(restored.distanceTo(point), lessThan(1e-8));
    final perspective = camera.projectionMatrix.values;
    camera.toggleProjection();
    expect(camera.projectionMode, CadProjectionMode.orthographic);
    expect(camera.projectionMatrix.values, isNot(perspective));
  });

  test('mesh adapter is the single kernel-to-scene boundary', () {
    final entity = MeshSceneAdapter.fromKernel(
      id: 'mesh-1',
      geometry: mesh,
      bounds: bounds,
    );
    expect(entity.kind, CadSceneEntityKind.mesh);
    expect(entity.geometry['nodes'], mesh.nodes);
    expect(entity.geometry['triangles'], mesh.triangles);
    expect((entity.geometry['bounds'] as Map)['min'], [-1, -1, 0]);
  });

  test('viewport picking uses the camera ray and mesh BVH', () {
    final scene = CadSceneGraph()
      ..upsert(
        MeshSceneAdapter.fromKernel(
          id: 'mesh-1',
          geometry: mesh,
          bounds: bounds,
        ),
      );
    final camera = CadCameraController(
      eye: const Vector3(0, 0, 5),
      target: Vector3.zero,
      up: const Vector3(0, 1, 0),
    )..resize(800, 600);
    final hit = ViewportPickingController().pick(
      position: const Offset(400, 300),
      camera: camera,
      scene: scene,
    );
    expect(hit?.entityId, 'mesh-1');
    expect(hit?.hit.triangleIndex, 0);
  });

  testWidgets('professional viewport renders scene controls', (tester) async {
    final scene = CadSceneGraph()
      ..upsert(
        MeshSceneAdapter.fromKernel(
          id: 'mesh-1',
          geometry: mesh,
          bounds: bounds,
        ),
      );
    final camera = CadCameraController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: ProfessionalCadViewportWidget(scene: scene, camera: camera),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Shaded'), findsOneWidget);
    expect(find.text('Wire'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('operational controller coordinates picking and recognition', () async {
    final cad = DesktopCadController(
      kernels: KernelManager(),
      projects: ProjectManager.instance,
    );
    final commands = DesktopCommandCoordinator(
      cad: cad,
      projects: ProjectManager.instance,
    );
    final controller = OperationalReverseEngineeringController(
      recognition: ProfessionalRecognitionApi(),
      commands: commands,
      runtime: cad.runtime,
    );
    addTearDown(controller.dispose);
    addTearDown(cad.dispose);
    const handle = KernelMeshHandle(
      persistentId: 'mesh',
      kernelId: 'kernel',
      fingerprint: 'fingerprint',
      vertexCount: 3,
      triangleCount: 1,
      bounds: bounds,
      hasNormals: false,
      metadata: {},
    );
    const document = ImportedCadDocument(
      id: 'document',
      projectId: 'project',
      sourcePath: 'part.stl',
      format: CadImportFormat.stl,
      registeredPath: 'CAD/part.stl',
      validation: [],
      mesh: handle,
    );
    final runtimeDirectory = await Directory.systemTemp.createTemp(
      'flcad-runtime-',
    );
    addTearDown(() => runtimeDirectory.delete(recursive: true));
    await cad.runtime.open('project', runtimeDirectory);
    await cad.runtime.registerImport(document, geometry: mesh);
    await controller.recognizePick(
      pick: const CadViewportPick(
        entityId: 'mesh-1',
        hit: MeshHit(triangleIndex: 0, point: Vector3.zero, distance: 5),
      ),
    );
    expect(controller.error, isNull);
    expect(controller.hypotheses, isNotEmpty);
    final id = controller.hypotheses.first.recognition.id;
    controller.decide(id, RecognitionDecision.accepted);
    expect(controller.decisions[id], RecognitionDecision.accepted);
  });

  test('operational controller completes rectangle to CAD surface', () async {
    final root = await Directory.systemTemp.createTemp('flcad_g102_');
    addTearDown(() => root.delete(recursive: true));
    final projects = ProjectRepository(
      storage: LocalStorageService(rootDirectory: root),
    );
    final projectDirectory = await projects.directoryFor('project');
    final references = ReferenceRepository(projects: projects);
    await references.save('project', [_planeReference]);
    final registeredStl = File(
      '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}Imports${Platform.pathSeparator}part.stl',
    );
    await registeredStl.parent.create(recursive: true);
    await registeredStl.writeAsString('solid restored\nendsolid restored');
    final importHistory = File(
      '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}ImportHistory${Platform.pathSeparator}history.jsonl',
    );
    await importHistory.parent.create(recursive: true);
    await importHistory.writeAsString(
      '${jsonEncode({'sourcePath': 'original.stl', 'registeredPath': registeredStl.path, 'format': 'stl', 'validation': <String>[]})}\n',
    );
    final referenceApi = ReferenceApi(
      engine: ReferenceEngine(repository: references),
    );
    final kernels = KernelManager()
      ..register(_OperationalSurfaceKernel(), makeDefault: true);
    final cad = DesktopCadController(
      kernels: kernels,
      projects: ProjectManager.instance,
      projectRepository: projects,
    );
    final commands = DesktopCommandCoordinator(
      cad: cad,
      projects: ProjectManager.instance,
      repository: projects,
    );
    await cad.restoreProjectGeometry('project');
    expect(cad.document?.isMesh, isTrue);
    expect(cad.meshGeometry?.triangles, [0, 1, 2]);
    final scene = cad.runtime.scene;
    final controller = OperationalReverseEngineeringController(
      recognition: ProfessionalRecognitionApi(),
      commands: commands,
      runtime: cad.runtime,
      referenceApi: referenceApi,
    );
    addTearDown(controller.dispose);
    addTearDown(cad.dispose);
    await controller.configureProject(
      projectId: 'project',
      projectDirectory: projectDirectory,
    );
    controller.activeContext = BridgeContext(
      projectId: 'project',
      meshId: 'mesh',
      meshFingerprint: 'fingerprint',
      userConfirmed: true,
      region: MeshRegion(
        id: 'region',
        meshId: 'mesh',
        triangleIndices: const [0],
        vertexIndices: const [0, 1, 2],
        points: const [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0)],
        normals: const [Vector3(0, 0, 1)],
        bounds: bounds,
        area: .5,
        connectivity: const {0: {}},
        fingerprint: 'region-fingerprint',
      ),
    );
    expect(scene.find(_planeReference.id), isNotNull);
    await controller.openSketch();
    await controller.drawRectangle(
      const SketchVector(-2, -1),
      const SketchVector(2, 1),
    );
    await controller.constrainRectangle();
    await controller.finishSketch();
    await controller.previewPlanarSurface();
    expect(scene.find('surface-preview'), isNotNull);
    await controller.confirmSurface();
    expect(controller.error, isNull);
    expect(controller.activeSurface?.valid, isTrue);
    expect(scene.find(controller.activeSurface!.surfaceId), isNotNull);
    await controller.undo();
    expect(scene.find(controller.activeSurface!.surfaceId), isNull);
    await controller.redo();
    expect(scene.find(controller.activeSurface!.surfaceId), isNotNull);
    await controller.persist();
    final reopenedScene = cad.runtime.scene;
    final reopened = OperationalReverseEngineeringController(
      recognition: ProfessionalRecognitionApi(),
      commands: commands,
      runtime: cad.runtime,
      referenceApi: ReferenceApi(
        engine: ReferenceEngine(repository: references),
      ),
    );
    addTearDown(reopened.dispose);
    await reopened.configureProject(
      projectId: 'project',
      projectDirectory: projectDirectory,
    );
    expect(reopened.sketchEntities, hasLength(4));
    expect(reopened.activeSurface?.handle, controller.activeSurface?.handle);
    expect(reopened.activeReference?.id, _planeReference.id);
    expect(reopenedScene.find(_planeReference.id), isNotNull);
    expect(reopenedScene.find(controller.activeSurface!.surfaceId), isNotNull);
  });
}

final _planeReference = ReferenceEntity(
  id: 'plane-reference',
  projectId: 'project',
  name: 'Base Plane',
  geometry: const PlaneGeometry(Vec3(0, 0, 0), Vec3(0, 0, 1)),
  mode: ReferenceMode.staticReference,
  status: ReferenceStatus.valid,
  dna: const ReferenceDNA('plane', 'region', 'z0', 'hash'),
  analytics: const ReferenceAnalytics(
    precision: 1,
    rmsError: 0,
    maxDeviation: 0,
    confidence: 1,
    fitQuality: 1,
    areaUsed: 1,
    coverage: 1,
    pointCount: 3,
  ),
  recipe: const ReferenceRecipe('plane', {}, ['region']),
  version: 1,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  dependencies: const ['region'],
  metadata: const {},
);

class _OperationalSurfaceKernel
    implements
        GeometryKernelAPI,
        MeshGeometryKernelAPI,
        SurfaceOperationKernelAPI {
  @override
  KernelDescriptor get descriptor => const KernelDescriptor(
    id: 'g102-test',
    name: 'G-102 contract kernel',
    version: '1',
    capabilities: KernelCapabilities({KernelCapability.planeSurface}),
    vendor: 'FLCAD',
  );
  @override
  Future<KernelHealth> healthCheck() async =>
      KernelHealth(KernelHealthStatus.healthy, 'ok', DateTime(2000));
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  @override
  Future<void> unload() async {}
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) async => ShapeHandle.reference(
    persistentId: persistentId,
    kernelId: descriptor.id,
    type: expectedType,
    fingerprint: 'surface-fingerprint',
  );
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      const [];
  @override
  Future<KernelMeshHandle> importStl(
    String path, {
    required String projectId,
    KernelImportFormat format = KernelImportFormat.autoDetect,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) async => const KernelMeshHandle(
    persistentId: 'restored-mesh',
    kernelId: 'g102-test',
    fingerprint: 'restored-fingerprint',
    vertexCount: 3,
    triangleCount: 1,
    bounds: KernelBounds(-1, -1, 0, 1, 1, 0),
    hasNormals: false,
    metadata: {},
  );
  @override
  Future<KernelMeshGeometry> inspectMesh(KernelMeshHandle handle) async =>
      const KernelMeshGeometry(
        nodes: [-1, -1, 0, 1, -1, 0, 0, 1, 0],
        triangles: [0, 1, 2],
      );
  @override
  Future<void> closeMesh(KernelMeshHandle handle) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
