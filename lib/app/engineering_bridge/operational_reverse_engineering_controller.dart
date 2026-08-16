import 'dart:io';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../core/cad_document/cad_document.dart';
import '../../core/cad_kernel/io/kernel_io_models.dart';
import '../../core/adaptive_surface/models/surface_geometry.dart';
import '../../core/adaptive_surface/continuity/surface_continuity.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';
import '../../core/professional_recognition/api/professional_recognition_api.dart';
import '../../core/professional_recognition/models/professional_recognition_models.dart';
import '../../core/professional_surface/api/professional_surface_modeling_api.dart';
import '../../core/professional_surface/models/professional_surface_models.dart';
import '../../core/professional_surface/repository/professional_surface_repository.dart';
import '../../core/reference_engine/api/reference_api.dart';
import '../../core/reference_engine/models/reference_entity.dart';
import '../../core/reference_engine/models/reference_geometry.dart';
import '../../core/reference_engine/serialization/reference_serializer.dart';
import '../../core/sketch_constraints/api/constraint_api.dart';
import '../../core/sketch_constraints/integration/constraint_factory.dart';
import '../../core/sketch_constraints/models/constraint_models.dart';
import '../../core/sketch_editor/api/sketch_editor_api.dart';
import '../../core/sketch_editor/integration/editor_factory.dart';
import '../../core/sketch_editor/models/editor_models.dart';
import '../../core/sketch_engine/api/sketch_engine_api.dart';
import '../../core/sketch_engine/entities/sketch_entities.dart';
import '../../core/sketch_engine/integration/sketch_factory.dart';
import '../../core/sketch_engine/models/sketch_models.dart';
import '../../core/smart_reference/models/smart_reference_models.dart';
import '../../core/smart_regions/api/smart_regions_api.dart';
import '../../core/surface_generation/api/surface_generation_api.dart';
import '../../core/surface_generation/integration/surface_generation_factory.dart';
import '../../core/surface_generation/models/surface_generation_models.dart';
import '../../core/surface_intelligence/api/surface_api.dart';
import '../../core/surface_intelligence/engine/surface_intelligence_engine.dart';
import '../../core/surface_intelligence/integration/surface_factory.dart';
import '../../core/surface_intelligence/models/surface_models.dart';
import '../../core/surface_operations/integration/surface_operations_factory.dart';
import '../cad_viewport/selection/viewport_picking_controller.dart';
import '../cad_viewport/camera/cad_camera_controller.dart';
import '../cad_viewport/rendering/reference_scene_adapter.dart';
import '../cad_viewport/rendering/sketch_scene_adapter.dart';
import '../cad_viewport/rendering/surface_scene_adapter.dart';
import '../cad_viewport/scene/cad_scene_graph.dart';
import '../commands/desktop_command_coordinator.dart';
import '../commands/command_registry.dart';
import 'adapters/mesh_region_smart_region_adapter.dart';
import 'adapters/reference_bridge.dart';
import 'adapters/recognition_bridge.dart';
import 'adapters/sketch_bridge.dart';
import 'adapters/smart_reference_recipe_mapper.dart';
import 'adapters/surface_bridge.dart';
import 'contracts/bridge_context.dart';
import 'contracts/bridge_selection.dart';
import 'selection/mesh_region_builder.dart';
import 'selection/geometry_selection_manager.dart';
import '../runtime/cad_runtime.dart';

enum RecognitionDecision { pending, accepted, rejected }

enum SketchSurfaceStage {
  idle,
  referenceReady,
  sketchActive,
  sketchFinished,
  surfacePreview,
  surfaceGenerated,
}

class OperationalReverseEngineeringController extends ChangeNotifier {
  OperationalReverseEngineeringController({
    required ProfessionalRecognitionApi recognition,
    required this.commands,
    required this.runtime,
    this.regionBuilder = const MeshRegionBuilder(),
    ReferenceApi? referenceApi,
    SmartRegionsApi? smartRegionsApi,
  }) : recognition = RecognitionBridge(recognition),
       _referenceApi = referenceApi ?? ReferenceApi(),
       _smartRegionsApi = smartRegionsApi ?? SmartRegionsApi();

  final RecognitionBridge recognition;
  final DesktopCommandCoordinator commands;
  final CadRuntime runtime;
  GeometrySelectionManager get geometrySelection => runtime.geometrySelection;
  final MeshRegionBuilder regionBuilder;
  ProfessionalRecognitionReport? get report =>
      runtime.read('recognition.report');
  set report(ProfessionalRecognitionReport? value) =>
      runtime.write('recognition.report', value);
  String? get recognitionFilter => runtime.read('recognition.filter');
  set recognitionFilter(String? value) =>
      runtime.write('recognition.filter', value);
  Map<String, RecognitionDecision> get decisions => runtime.readOrCreate(
    'recognition.decisions',
    () => <String, RecognitionDecision>{},
  );
  bool get busy => runtime.read<bool>('operation.busy') ?? false;
  set busy(bool value) => runtime.write('operation.busy', value);
  String? get error => runtime.read('operation.error');
  set error(String? value) => runtime.write('operation.error', value);
  CadViewportPick? get activePick => runtime.read('selection.pick');
  set activePick(CadViewportPick? value) =>
      runtime.write('selection.pick', value);
  BridgeSelection? get activeSelection => runtime.read('selection.bridge');
  set activeSelection(BridgeSelection? value) =>
      runtime.write('selection.bridge', value);
  BridgeContext? get activeContext => runtime.read('session.context');
  set activeContext(BridgeContext? value) =>
      runtime.write('session.context', value);
  String? get configuredProjectId => runtime.read('project.configuredId');
  set configuredProjectId(String? value) =>
      runtime.write('project.configuredId', value);
  SketchEngineApi? get sketchApi => runtime.read('sketch.api');
  set sketchApi(SketchEngineApi? value) => runtime.write('sketch.api', value);
  SketchEditorApi? get editorApi => runtime.read('sketch.editorApi');
  set editorApi(SketchEditorApi? value) =>
      runtime.write('sketch.editorApi', value);
  ConstraintApi? get constraintApi => runtime.read('sketch.constraintApi');
  set constraintApi(ConstraintApi? value) =>
      runtime.write('sketch.constraintApi', value);
  SurfaceIntelligenceApi? get surfacePlanningApi =>
      runtime.read('surface.planningApi');
  set surfacePlanningApi(SurfaceIntelligenceApi? value) =>
      runtime.write('surface.planningApi', value);
  SurfaceGenerationApi? get surfaceGenerationApi =>
      runtime.read('surface.generationApi');
  set surfaceGenerationApi(SurfaceGenerationApi? value) =>
      runtime.write('surface.generationApi', value);
  ProfessionalSurfaceModelingApi? get professionalSurfaceApi =>
      runtime.read('surface.professionalApi');
  set professionalSurfaceApi(ProfessionalSurfaceModelingApi? value) =>
      runtime.write('surface.professionalApi', value);
  SurfacePreviewState? get professionalSurfacePreview =>
      runtime.read('surface.preview');
  set professionalSurfacePreview(SurfacePreviewState? value) =>
      runtime.write('surface.preview', value);
  ReferenceEntity? get activeReference => runtime.read('reference.active');
  set activeReference(ReferenceEntity? value) =>
      runtime.write('reference.active', value);
  Sketch? get activeSketch => runtime.read('sketch.active');
  set activeSketch(Sketch? value) => runtime.write('sketch.active', value);
  SurfacePlan? get surfacePlan => runtime.read('surface.plan');
  set surfacePlan(SurfacePlan? value) => runtime.write('surface.plan', value);
  GeneratedSurface? get activeSurface => runtime.read('surface.active');
  set activeSurface(GeneratedSurface? value) =>
      runtime.write('surface.active', value);
  SketchSurfaceStage get stage =>
      runtime.read<SketchSurfaceStage>('surface.stage') ??
      SketchSurfaceStage.idle;
  set stage(SketchSurfaceStage value) => runtime.write('surface.stage', value);
  SketchToolType get activeTool =>
      runtime.read<SketchToolType>('sketch.tool') ?? SketchToolType.rectangle;
  set activeTool(SketchToolType value) => runtime.write('sketch.tool', value);
  List<SketchVector> get previewPoints =>
      runtime.read<List<SketchVector>>('sketch.previewPoints') ?? const [];
  set previewPoints(List<SketchVector> value) =>
      runtime.write('sketch.previewPoints', value);
  Set<String> get selectedSketchEntityIds =>
      runtime.readOrCreate('sketch.selectedIds', () => <String>{});
  final ReferenceApi _referenceApi;
  final SmartRegionsApi _smartRegionsApi;
  final ReferenceSceneAdapter _referenceScene = const ReferenceSceneAdapter();
  final SketchSceneAdapter _sketchScene = const SketchSceneAdapter();
  final SurfaceSceneAdapter _surfaceScene = const SurfaceSceneAdapter();
  final ViewportPickingController _viewportPicking =
      ViewportPickingController();
  bool get _commandsRegistered =>
      runtime.read<bool>('commands.registered') ?? false;
  set _commandsRegistered(bool value) =>
      runtime.write('commands.registered', value);

  List<SketchEntity> get sketchEntities => sketchApi == null
      ? const []
      : activeSketch?.entityIds
                .map(sketchApi!.entity)
                .whereType<SketchEntity>()
                .toList() ??
            const [];
  List<SketchConstraint> get constraints =>
      constraintApi?.constraints ?? const [];

  Future<void> configureProject({
    required String projectId,
    required Directory projectDirectory,
  }) async {
    if (configuredProjectId == projectId) return;
    configuredProjectId = projectId;
    final sketch = const SketchEngineFactory().create(projectDirectory);
    final constraints = const ConstraintFactory().create(
      projectDirectory: projectDirectory,
      sketch: sketch,
    );
    sketchApi = sketch;
    constraintApi = constraints;
    editorApi = const SketchEditorFactory().create(
      projectDirectory: projectDirectory,
      sketch: sketch,
      constraints: constraints,
    );
    surfacePlanningApi = const SurfaceIntelligenceFactory().create(
      projectDirectory: projectDirectory,
    );
    surfaceGenerationApi = SurfaceGenerationFactory(
      commands.cad.kernels,
    ).create(projectId: projectId, projectDirectory: projectDirectory);
    final activeKernel = commands.cad.kernels.active;
    if (activeKernel is! SurfaceOperationKernelAPI) {
      throw StateError(
        'The active geometry kernel does not expose surface operations.',
      );
    }
    final surfaceKernel = activeKernel as SurfaceOperationKernelAPI;
    professionalSurfaceApi = ProfessionalSurfaceModelingApi(
      projectId: projectId,
      kernel: activeKernel,
      generation: surfaceGenerationApi!,
      operations: const SurfaceOperationsFactory().create(
        projectDirectory: projectDirectory,
        kernel: surfaceKernel,
      ),
      repository: ProfessionalSurfaceRepository(projectDirectory),
    );
    await sketch.load();
    await constraints.load();
    final surfaces = await surfaceGenerationApi!.load();
    for (final surface in surfaces) {
      await _upsertSurface(surface, command: 'restore.surface');
    }
    activeSurface = surfaces.lastOrNull;
    final professionalSurfaces = await professionalSurfaceApi!.load();
    for (final surface in professionalSurfaces) {
      final handle = surface.handle;
      if (handle != null) {
        await _upsertProfessionalSurface(surface, command: 'restore.surface');
      }
    }
    final references = await _referenceApi.list(projectId);
    for (final reference in references.where(
      (item) => item.status == ReferenceStatus.valid,
    )) {
      await _upsertReference(reference, command: 'restore.reference');
    }
    activeReference = references
        .where(
          (item) =>
              item.status == ReferenceStatus.valid &&
              item.geometry is PlaneGeometry,
        )
        .lastOrNull;
    if (sketch.sketches.isNotEmpty) {
      activeSketch = sketch.sketches.first;
      await _synchronizeSketchScene();
    }
    if (activeSurface != null) {
      stage = SketchSurfaceStage.surfaceGenerated;
    } else if (activeSketch != null) {
      stage = SketchSurfaceStage.sketchFinished;
    } else if (activeReference != null) {
      stage = SketchSurfaceStage.referenceReady;
    }
    _registerOperationalCommands();
    notifyListeners();
  }

  void detachProject() {
    configuredProjectId = null;
    activeReference = null;
    activeSketch = null;
    activeSurface = null;
    surfacePlan = null;
    activeContext = null;
    activeSelection = null;
    previewPoints = const [];
    selectedSketchEntityIds.clear();
    sketchApi = null;
    editorApi = null;
    constraintApi = null;
    surfacePlanningApi = null;
    surfaceGenerationApi = null;
    professionalSurfaceApi = null;
    professionalSurfacePreview = null;
    stage = SketchSurfaceStage.idle;
    notifyListeners();
  }

  Future<void> recognizePick({required CadViewportPick pick}) async {
    final document =
        runtime.activeImport ??
        (throw StateError('CadRuntime has no active imported geometry.'));
    final geometry =
        runtime.activeMeshGeometry ??
        (throw StateError('CadRuntime has no active display mesh.'));
    activePick = pick;
    recognitionFilter = null;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final selection = BridgeSelection(
        id: '${document.id}:triangle:${pick.hit.triangleIndex}',
        entityId: pick.entityId,
        kind: BridgeSelectionKind.triangle,
        geometry: geometry,
        triangleIndices: {pick.hit.triangleIndex},
      );
      final region = regionBuilder.build(
        meshId: document.id,
        selection: selection,
      );
      final context = BridgeContext(
        projectId: document.projectId,
        meshId: document.id,
        meshFingerprint: document.mesh!.fingerprint,
        userConfirmed: false,
        region: region,
      );
      report = await recognition.recognize(context);
      activeSelection = selection;
      activeContext = context;
      decisions
        ..clear()
        ..addEntries(
          hypotheses.map(
            (hypothesis) => MapEntry(
              hypothesis.recognition.id,
              RecognitionDecision.pending,
            ),
          ),
        );
      await commands.dispatch('selection.set', {
        'ids': [selection.id],
      });
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  List<ProfessionalPrimitive> get hypotheses {
    final values = report?.primitives ?? const <ProfessionalPrimitive>[];
    final filter = recognitionFilter;
    return filter == null
        ? values
        : values
              .where((item) => item.recognition.winner.type.name == filter)
              .toList();
  }

  bool get canDetect => activeContext != null;

  Future<void> detect(String primitiveType) async {
    final context = activeContext;
    if (context == null) {
      throw StateError('Select a mesh region before running detection.');
    }
    busy = true;
    error = null;
    recognitionFilter = primitiveType;
    notifyListeners();
    try {
      report = await recognition.recognize(context);
      for (final primitive in hypotheses) {
        decisions.putIfAbsent(
          primitive.recognition.id,
          () => RecognitionDecision.pending,
        );
      }
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void decide(String id, RecognitionDecision decision) {
    if (!decisions.containsKey(id)) {
      throw StateError(
        'Recognition hypothesis $id is not part of the active report.',
      );
    }
    decisions[id] = decision;
    notifyListeners();
  }

  Future<void> createRecognizedPlane() => _run('reverse.reference.plane');
  Future<void> createAxis() => _run('reverse.reference.axis');
  Future<void> createPoint() => _run('reverse.reference.point');
  Future<void> createCoordinateSystem() =>
      _run('reverse.reference.coordinateSystem');
  Future<void> openSketch() => _run('reverse.sketch.open');
  Future<void> drawRectangle(SketchVector first, SketchVector second) => _run(
    'reverse.sketch.rectangle',
    {'first': first.toJson(), 'second': second.toJson()},
  );
  void selectSketchTool(SketchToolType tool) {
    if (!{
      SketchToolType.line,
      SketchToolType.arc,
      SketchToolType.circle,
      SketchToolType.rectangle,
      SketchToolType.spline,
    }.contains(tool)) {
      throw StateError(
        'Sketch tool ${tool.name} is not exposed by this workspace.',
      );
    }
    activeTool = tool;
    previewPoints = const [];
    notifyListeners();
  }

  Future<void> captureSketchTap(
    Offset position,
    CadCameraController camera,
  ) async {
    final geometry = activeReference?.geometry;
    if (geometry is! PlaneGeometry ||
        stage != SketchSurfaceStage.sketchActive) {
      return;
    }
    Vector3 vector(List<double> value) => Vector3(value[0], value[1], value[2]);
    final origin = vector(geometry.origin.toJson());
    final normal = vector(geometry.normal.toJson()).normalized;
    final world = _viewportPicking.pointOnPlane(
      position: position,
      camera: camera,
      origin: origin,
      normal: normal,
    );
    if (world == null) return;
    final xAxis = geometry.xDirection == null
        ? normal
              .cross(
                normal.z.abs() < .9
                    ? const Vector3(0, 0, 1)
                    : const Vector3(0, 1, 0),
              )
              .normalized
        : vector(geometry.xDirection!.toJson()).normalized;
    final yAxis = normal.cross(xAxis).normalized;
    final delta = world - origin;
    final raw = SketchVector(delta.dot(xAxis), delta.dot(yAxis));
    final point = editorApi?.snap(raw)?.position ?? raw;
    previewPoints = [...previewPoints, point];
    notifyListeners();
    final requiredPoints = activeTool == SketchToolType.spline ? 4 : 2;
    if (previewPoints.length == requiredPoints) {
      final points = previewPoints;
      previewPoints = const [];
      await _run('reverse.sketch.draw', {
        'tool': activeTool.name,
        'points': points.map((item) => item.toJson()).toList(),
      });
    }
  }

  Future<void> constrainRectangle() =>
      _run('reverse.sketch.constrainRectangle');
  Future<void> applyConstraint(SketchConstraintType type, {double? value}) =>
      _run('reverse.sketch.constraint', {
        'type': type.name,
        'value': ?value,
        'references': selectedSketchEntityIds.toList()..sort(),
      });
  void toggleSketchSelection(String id) {
    if (!selectedSketchEntityIds.add(id)) {
      selectedSketchEntityIds.remove(id);
    }
    runtime.select(selectedSketchEntityIds);
    notifyListeners();
  }

  Future<void> finishSketch() => _run('reverse.sketch.finish');
  Future<void> previewPlanarSurface() => _run('reverse.surface.preview');
  Future<void> confirmSurface() => _run('reverse.surface.confirm');
  bool canCreateRecognizedSurface(SurfaceKind kind) {
    final primitive = (report?.primitives ?? const <ProfessionalPrimitive>[])
        .where((item) => item.recognition.winner.type.name == kind.name)
        .firstOrNull;
    return primitive != null &&
        decisions[primitive.recognition.id] == RecognitionDecision.accepted &&
        {SurfaceKind.cylinder, SurfaceKind.sphere}.contains(kind);
  }

  Future<void> createRecognizedSurface(SurfaceKind kind) async {
    final primitive = (report?.primitives ?? const <ProfessionalPrimitive>[])
        .where((item) => item.recognition.winner.type.name == kind.name)
        .firstOrNull;
    if (primitive == null || !canCreateRecognizedSurface(kind)) {
      throw StateError('Accept a ${kind.name} hypothesis first.');
    }
    final api = surfaceGenerationApi!;
    final recognition = primitive.recognition;
    final parameters = recognition.winner.parameters;
    final confidence = recognition.dna.confidence;
    final candidate = SurfaceCandidate(
      id: 'recognized-surface:${recognition.id}',
      kind: kind,
      classification: SurfaceClassification.analytical,
      confidence: confidence,
      evidence: [
        SurfacePlanningEvidence(
          id: 'recognition:${recognition.id}',
          source: 'ProfessionalRecognitionApi',
          description: recognition.explanation.why,
          value: recognition.explanation.score,
          regionId: recognition.winner.regionId,
        ),
      ],
      regionIds: [recognition.winner.regionId],
      boundaries: const [],
      quality: recognition.winner.statistics.score,
      coverage: recognition.winner.statistics.coverage,
      predictedContinuity: SurfaceContinuityLevel.g0,
      justification: recognition.explanation.why,
    );
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = switch (kind) {
        SurfaceKind.cylinder => await api.cylinder.fromCandidate(
          candidate,
          axisOrigin: (parameters['origin'] as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList(),
          axisDirection: (parameters['axis'] as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList(),
          radius: (parameters['radius'] as num).toDouble(),
        ),
        SurfaceKind.sphere => await api.sphere.fromCandidate(
          candidate,
          center: (parameters['center'] as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList(),
          radius: (parameters['radius'] as num).toDouble(),
        ),
        _ => throw StateError('${kind.name} is not mapped by Recognition.'),
      };
      if (!result.success) {
        throw StateError(
          result.diagnostics.map((item) => item.message).join('; '),
        );
      }
      activeSurface = result.surface;
      await _upsertSurface(activeSurface!, command: 'surface.recognition');
      stage = SketchSurfaceStage.surfaceGenerated;
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool canPreviewProfessional(ProfessionalSurfaceTool tool) {
    final count = geometrySelection.shapeHandles.length;
    return switch (tool) {
      ProfessionalSurfaceTool.loft ||
      ProfessionalSurfaceTool.blend => count >= 2,
      ProfessionalSurfaceTool.sweep => count == 2,
      ProfessionalSurfaceTool.fill ||
      ProfessionalSurfaceTool.patch => count >= 1,
      _ => false,
    };
  }

  Future<void> previewProfessionalSurface(ProfessionalSurfaceTool tool) async {
    final api = professionalSurfaceApi;
    final handles = geometrySelection.shapeHandles;
    if (api == null || !canPreviewProfessional(tool)) {
      throw StateError('Select valid kernel shapes for ${tool.name}.');
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final draft = api.begin(
        tool: tool,
        references: handles.map((item) => item.persistentId).toList(),
        parameters: {
          'shapeHandles': handles.map((item) => item.toJson()).toList(),
        },
      );
      professionalSurfacePreview = await api.preview(draft.definition.id);
      final handle = professionalSurfacePreview!.definition.handle;
      if (handle != null) {
        await runtime.showTransientShape(
          _professionalSurfaceVisual(
            professionalSurfacePreview!.definition,
            preview: true,
          ),
          handle,
        );
      }
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> confirmProfessionalSurface() async {
    final preview = professionalSurfacePreview;
    if (preview == null || professionalSurfaceApi == null) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final confirmed = await professionalSurfaceApi!.confirm(
        preview.definition.id,
      );
      runtime.hideTransient('preview:${confirmed.id}');
      await _upsertProfessionalSurface(
        confirmed,
        command: 'surface.professional.confirm',
      );
      professionalSurfacePreview = null;
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void cancelProfessionalSurface() {
    final preview = professionalSurfacePreview;
    if (preview == null || professionalSurfaceApi == null) return;
    professionalSurfaceApi!.cancel(preview.definition.id);
    runtime.hideTransient('preview:${preview.definition.id}');
    professionalSurfacePreview = null;
    notifyListeners();
  }

  Future<void> undo() async {
    await commands.undo();
    await _synchronizeSketchScene();
    notifyListeners();
  }

  Future<void> redo() async {
    await commands.redo();
    await _synchronizeSketchScene();
    notifyListeners();
  }

  Future<void> persist() async {
    await sketchApi?.persist();
    await editorApi?.persist();
    await constraintApi?.persist();
  }

  Future<void> saveProject() async {
    await persist();
    await commands.dispatch('project.save');
  }

  Future<void> _run(
    String id, [
    Map<String, Object?> parameters = const {},
  ]) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await commands.dispatch(id, parameters);
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _registerOperationalCommands() {
    if (_commandsRegistered) return;
    _commandsRegistered = true;
    void register({
      required String id,
      required Future<Object?> Function(Map<String, Object?>) execute,
      required Future<Object?> Function(Map<String, Object?>) undo,
      Future<Object?> Function(Map<String, Object?>)? redo,
    }) => commands.registry.register(
      RegisteredEngineeringCommand(
        id: id,
        module: 'SketchSurface',
        execute: (_, parameters) => execute(parameters),
        undo: (_, parameters) => undo(parameters),
        redo: (_, parameters) => (redo ?? execute)(parameters),
      ),
    );

    ReferenceEntity? referenceCommandValue;
    register(
      id: 'reverse.reference.plane',
      execute: (_) async {
        final context = activeContext;
        final selection = activeSelection;
        final primitive =
            (report?.primitives ?? const <ProfessionalPrimitive>[])
                .where((item) => item.recognition.winner.type.name == 'plane')
                .firstOrNull;
        if (context == null || selection == null || primitive == null) {
          throw StateError('An accepted planar recognition is required.');
        }
        if (decisions[primitive.recognition.id] !=
            RecognitionDecision.accepted) {
          throw StateError(
            'Accept the planar hypothesis before creating its reference.',
          );
        }
        final adaptation = await MeshRegionSmartRegionAdapter(_smartRegionsApi)
            .adapt(
              context: context,
              selection: selection,
              name: 'Recognized planar region',
            );
        final confidence = primitive.recognition.dna.confidence;
        final candidate = ReferenceCandidate(
          id: 'reference:${primitive.recognition.id}',
          type: ReferenceCandidateType.basePlane,
          scores: ReferenceScores(
            geometricScore: primitive.recognition.explanation.score,
            topologyScore: confidence,
            manufacturingScore: 0,
            functionalScore: 0,
            symmetryScore: 0,
            featureScore: 0,
            contextScore: confidence,
            historyScore: 0,
            overallConfidence: confidence,
          ),
          evidence: [
            ReferenceEvidence(
              id: 'evidence:${primitive.recognition.id}',
              source: 'ProfessionalRecognitionApi',
              description: primitive.recognition.explanation.why,
              primitiveIds: [primitive.recognition.id],
              featureIds: const [],
              score: primitive.recognition.explanation.score,
            ),
          ],
          justification: primitive.recognition.explanation.why,
          primitiveIds: [primitive.recognition.id],
          featureIds: const [],
          topologicalRelationships: const [],
          discardedHypotheses:
              primitive.recognition.explanation.losingCandidates,
          canonical: CanonicalReferenceSuggestion(
            measuredReference: primitive.recognition.id,
            canonicalReference: 'recognized-plane',
            angularErrorDegrees: 0,
            confidence: confidence,
            justification: primitive.recognition.explanation.why,
            reasons: primitive.auditTrail,
          ),
        );
        final recipe = const SmartReferenceRecipeMapper().map(
          candidate: candidate,
          region: adaptation.region,
        );
        referenceCommandValue = await ReferenceBridge(_referenceApi)
            .createApproved(
              context: context.copyWith(userConfirmed: true),
              candidate: candidate,
              recipe: recipe,
              name: 'Recognized Base Plane',
              meshes: {adaptation.mesh.id: adaptation.mesh},
              regions: {adaptation.region.id: adaptation.region},
            );
        activeReference = referenceCommandValue;
        await _upsertReference(
          referenceCommandValue!,
          command: 'reference.recognition',
        );
        stage = SketchSurfaceStage.referenceReady;
        return referenceCommandValue!.id;
      },
      undo: (_) async {
        final value = referenceCommandValue;
        if (value != null) {
          await ReferenceBridge(_referenceApi).undo(value);
          await runtime.removeEntity(value.id, command: 'reference.undo');
        }
        activeReference = null;
        stage = SketchSurfaceStage.idle;
        return 'reference removed';
      },
      redo: (_) async {
        final value = referenceCommandValue;
        if (value == null) throw StateError('No reference to restore.');
        await ReferenceBridge(_referenceApi).redo(value);
        activeReference = value;
        await _upsertReference(value, command: 'reference.redo');
        stage = SketchSurfaceStage.referenceReady;
        return value.id;
      },
    );

    final createdReferences = <String, ReferenceEntity?>{};
    void registerDerivedReference({
      required String id,
      required String name,
      required ReferenceRecipe Function(PlaneGeometry) recipe,
    }) {
      register(
        id: id,
        execute: (_) async {
          final plane = activeReference?.geometry;
          if (plane is! PlaneGeometry || configuredProjectId == null) {
            throw StateError('Create an approved plane first.');
          }
          final value = await _referenceApi.create(
            projectId: configuredProjectId!,
            name: name,
            mode: ReferenceMode.staticReference,
            recipe: recipe(plane),
          );
          createdReferences[id] = value;
          await _upsertReference(value, command: 'reference.create');
          return value.id;
        },
        undo: (_) async {
          final value = createdReferences[id];
          if (value != null) {
            await _referenceApi.delete(value);
            await runtime.removeEntity(value.id, command: 'reference.undo');
          }
          return '$name removed';
        },
        redo: (_) async {
          final value = createdReferences[id];
          if (value == null) throw StateError('No $name to restore.');
          await _referenceApi.restore(value);
          await _upsertReference(value, command: 'reference.redo');
          return value.id;
        },
      );
    }

    registerDerivedReference(
      id: 'reverse.reference.axis',
      name: 'Plane Normal Axis',
      recipe: (plane) => ReferenceRecipe(
        'axis',
        const {'method': 'normal'},
        [activeReference!.id],
      ),
    );
    registerDerivedReference(
      id: 'reverse.reference.point',
      name: 'Plane Origin Point',
      recipe: (plane) => ReferenceRecipe('point', {
        'method': 'explicit',
        'point': plane.origin.toJson(),
      }, const []),
    );
    registerDerivedReference(
      id: 'reverse.reference.coordinateSystem',
      name: 'Plane Coordinate System',
      recipe: (plane) {
        final normal = plane.normal;
        final x = plane.xDirection;
        if (x == null) {
          throw StateError('The approved plane has no X direction.');
        }
        final y = normal.cross(x).normalized;
        return ReferenceRecipe('coordinateSystem', {
          'origin': plane.origin.toJson(),
          'xAxis': x.toJson(),
          'yAxis': y.toJson(),
        }, const []);
      },
    );

    Sketch? sketchCommandValue;
    register(
      id: 'reverse.sketch.open',
      execute: (_) async {
        final reference = activeReference;
        final context = activeContext;
        if (reference == null || context == null) {
          throw StateError('Create the approved plane before opening Sketch.');
        }
        sketchCommandValue = SketchBridge(sketchApi!).openFromApprovedPlane(
          context: context.copyWith(userConfirmed: true),
          plane: reference,
          name: 'Surface Profile',
        );
        activeSketch = sketchCommandValue;
        stage = SketchSurfaceStage.sketchActive;
        return sketchCommandValue!.id;
      },
      undo: (_) async {
        if (sketchCommandValue != null) {
          SketchBridge(sketchApi!).undo(sketchCommandValue!);
        }
        activeSketch = null;
        stage = SketchSurfaceStage.referenceReady;
        await _synchronizeSketchScene();
        return 'sketch removed';
      },
    );

    register(
      id: 'reverse.sketch.rectangle',
      execute: (parameters) async {
        if (activeSketch == null) throw StateError('Open Sketch first.');
        final first = SketchVector.fromJson(parameters['first']);
        final second = SketchVector.fromJson(parameters['second']);
        final operation = editorApi!.preview(SketchToolType.rectangle, [
          first,
          second,
        ]);
        final created = editorApi!.confirm(operation.id);
        previewPoints = const [];
        await _synchronizeSketchScene();
        return created.map((item) => item.id).join(',');
      },
      undo: (_) async {
        editorApi!.undo();
        await _synchronizeSketchScene();
        return 'rectangle undone';
      },
      redo: (_) async {
        editorApi!.redo();
        await _synchronizeSketchScene();
        return 'rectangle restored';
      },
    );

    register(
      id: 'reverse.sketch.draw',
      execute: (parameters) async {
        if (activeSketch == null) throw StateError('Open Sketch first.');
        final tool = SketchToolType.values.byName(
          parameters['tool']! as String,
        );
        final points = (parameters['points']! as List)
            .map(SketchVector.fromJson)
            .toList();
        final operation = editorApi!.preview(tool, points);
        final created = editorApi!.confirm(operation.id);
        await _synchronizeSketchScene();
        return created.map((item) => item.id).join(',');
      },
      undo: (_) async {
        editorApi!.undo();
        await _synchronizeSketchScene();
        return 'sketch tool undone';
      },
      redo: (_) async {
        editorApi!.redo();
        await _synchronizeSketchScene();
        return 'sketch tool restored';
      },
    );

    final rectangleConstraints = <SketchConstraint>[];
    register(
      id: 'reverse.sketch.constrainRectangle',
      execute: (_) async {
        final lines = sketchEntities.whereType<SketchLine>().toList();
        if (lines.length < 4) {
          throw StateError('A four-line rectangle is required.');
        }
        rectangleConstraints.clear();
        for (var index = 0; index < 4; index++) {
          rectangleConstraints.add(
            (index.isEven
                    ? constraintApi!.builders.horizontal
                    : constraintApi!.builders.vertical)
                .build([lines[index].id]),
          );
        }
        for (var index = 0; index < 4; index++) {
          rectangleConstraints.add(
            constraintApi!.builders.coincident.build([
              lines[index].id,
              lines[(index + 1) % 4].id,
            ]),
          );
        }
        await constraintApi!.solve();
        await _synchronizeSketchScene();
        return '${rectangleConstraints.length} constraints';
      },
      undo: (_) async {
        for (final constraint in rectangleConstraints.toList().reversed) {
          constraintApi!.delete(constraint.id);
        }
        await _synchronizeSketchScene();
        return 'constraints removed';
      },
    );

    register(
      id: 'reverse.sketch.constraint',
      execute: (parameters) async {
        final type = SketchConstraintType.values.byName(
          parameters['type']! as String,
        );
        final references = (parameters['references']! as List).cast<String>();
        if (references.isEmpty) {
          throw StateError(
            'Select Sketch entities before applying a constraint.',
          );
        }
        final explicitConstraint = constraintApi!.builders
            .of(type)
            .build(
              references,
              value: (parameters['value'] as num?)?.toDouble(),
            );
        parameters['createdId'] = explicitConstraint.id;
        await constraintApi!.solve(only: [explicitConstraint.id]);
        await _synchronizeSketchScene();
        return explicitConstraint.id;
      },
      undo: (parameters) async {
        final id = parameters['createdId'] as String?;
        if (id != null) {
          constraintApi!.delete(id);
        }
        await _synchronizeSketchScene();
        return 'constraint removed';
      },
    );

    register(
      id: 'reverse.sketch.finish',
      execute: (_) async {
        if (sketchEntities.isEmpty) throw StateError('Sketch is empty.');
        await persist();
        sketchApi!.closeSketch();
        stage = SketchSurfaceStage.sketchFinished;
        return activeSketch!.id;
      },
      undo: (_) async {
        sketchApi!.openSketch(activeSketch!.id);
        stage = SketchSurfaceStage.sketchActive;
        return activeSketch!.id;
      },
    );

    register(
      id: 'reverse.surface.preview',
      execute: (_) async {
        final rectangle = _rectangleBounds();
        final reference = activeReference;
        if (reference?.geometry is! PlaneGeometry) {
          throw StateError('A planar reference is required.');
        }
        final plane = reference!.geometry as PlaneGeometry;
        final request = SurfacePlanningRequest(
          projectId: configuredProjectId!,
          evidence: [
            SurfacePlanningEvidence(
              id: 'sketch:${activeSketch!.id}',
              source: 'SketchEngineApi planar profile',
              description: 'planar closed rectangle',
              value: 1,
            ),
          ],
          boundaries: List.generate(
            4,
            (index) => BoundarySegment(
              'boundary:$index',
              'corner:$index',
              'corner:${(index + 1) % 4}',
            ),
          ),
          regionIds: [activeContext!.region!.id],
          coverageByKind: const {SurfaceKind.plane: 1},
        );
        surfacePlan = await surfacePlanningApi!.plan(request);
        final candidate = surfacePlan!.candidates
            .where((item) => item.kind == SurfaceKind.plane)
            .firstOrNull;
        if (candidate == null) {
          throw StateError('Planner produced no planar candidate.');
        }
        runtime.showTransient(
          _surfaceScene.planarPreview(
            id: 'surface-preview',
            origin: plane.origin.toJson(),
            normal: plane.normal.toJson(),
            width: rectangle.$1,
            height: rectangle.$2,
            quality: candidate.quality,
            continuity: candidate.predictedContinuity.name,
          ),
        );
        stage = SketchSurfaceStage.surfacePreview;
        return surfacePlan!.id;
      },
      undo: (_) async {
        runtime.hideTransient('surface-preview');
        surfacePlan = null;
        stage = SketchSurfaceStage.sketchFinished;
        return 'preview removed';
      },
    );

    register(
      id: 'reverse.surface.confirm',
      execute: (_) async {
        final plan =
            surfacePlan ?? (throw StateError('Preview the surface first.'));
        final plane = activeReference!.geometry as PlaneGeometry;
        final rectangle = _rectangleBounds();
        final candidate = plan.candidates.firstWhere(
          (item) => item.kind == SurfaceKind.plane,
        );
        final results = await SurfaceBridge(surfaceGenerationApi!)
            .generateApproved(
              context: activeContext!.copyWith(userConfirmed: true),
              sketch: activeSketch!,
              plan: plan,
              parameters: {
                candidate.id: {
                  'origin': plane.origin.toJson(),
                  'normal': plane.normal.toJson(),
                  'lowerBound': -rectangle.$1 / 2,
                  'upperBound': rectangle.$1 / 2,
                  'width': rectangle.$1,
                  'height': rectangle.$2,
                },
              },
            );
        final result = results.where((item) => item.success).firstOrNull;
        if (result?.surface == null) {
          throw StateError('CAD kernel rejected surface generation.');
        }
        activeSurface = result!.surface;
        runtime.hideTransient('surface-preview');
        await _upsertSurface(activeSurface!, command: 'surface.confirm');
        stage = SketchSurfaceStage.surfaceGenerated;
        return activeSurface!.surfaceId;
      },
      undo: (_) async {
        if (activeSurface != null) {
          await runtime.removeEntity(
            activeSurface!.surfaceId,
            command: 'surface.undo',
          );
        }
        stage = SketchSurfaceStage.surfacePreview;
        return 'surface hidden';
      },
      redo: (_) async {
        if (activeSurface == null) {
          throw StateError('No generated surface to restore.');
        }
        await _upsertSurface(activeSurface!, command: 'surface.redo');
        stage = SketchSurfaceStage.surfaceGenerated;
        return activeSurface!.surfaceId;
      },
    );
  }

  (double, double) _rectangleBounds() {
    final points = sketchEntities
        .whereType<SketchLine>()
        .expand(
          (line) => [
            SketchVector.fromJson(line.parameters['start']),
            SketchVector.fromJson(line.parameters['end']),
          ],
        )
        .toList();
    if (points.isEmpty) throw StateError('A rectangular profile is required.');
    final xs = points.map((point) => point.x).toList();
    final ys = points.map((point) => point.y).toList();
    xs.sort();
    ys.sort();
    return (xs.last - xs.first, ys.last - ys.first);
  }

  Future<void> _upsertReference(
    ReferenceEntity reference, {
    required String command,
  }) => runtime.upsertEntity(
    command: command,
    kind: CadDocumentEntityKind.reference,
    entity: _referenceScene.adapt(reference),
    data: {'reference': ReferenceSerializer.toJson(reference)},
  );

  CadSceneEntity _professionalSurfaceVisual(
    ProfessionalSurfaceDefinition value, {
    bool preview = false,
  }) => CadSceneEntity(
    id: preview ? 'preview:${value.id}' : value.id,
    kind: preview ? CadSceneEntityKind.preview : CadSceneEntityKind.surface,
    transparent: preview,
    geometry: {
      'featureId': value.id,
      'tool': value.tool.name,
      'handle': value.handle?.toJson(),
      'parameters': value.parameters,
      'references': value.references,
      'continuity': value.continuity.name,
    },
  );

  Future<void> _upsertProfessionalSurface(
    ProfessionalSurfaceDefinition value, {
    required String command,
  }) => runtime.upsertEntity(
    command: command,
    kind: CadDocumentEntityKind.surface,
    entity: _professionalSurfaceVisual(value),
    shape: value.handle,
    officialShape: value.handle != null,
    data: {'professionalSurface': value.toJson()},
  );

  Future<void> _upsertSurface(
    GeneratedSurface surface, {
    required String command,
  }) => runtime.upsertEntity(
    command: command,
    kind: CadDocumentEntityKind.surface,
    entity: _surfaceScene.adapt(surface),
    shape: surface.handle,
    officialShape: true,
    data: {'surface': surface.toJson()},
  );

  Future<void> _synchronizeSketchScene() async {
    final document = runtime.document;
    if (document == null) return;
    final currentIds = {
      ...sketchEntities.map((item) => item.id),
      if (activeSketch != null) activeSketch!.id,
    };
    final constraintIds = constraints.map((item) => item.id).toSet();
    final stale = document.entities.values
        .where((item) => item.kind == CadDocumentEntityKind.sketch)
        .map((item) => item.id)
        .where((id) => !currentIds.contains(id));
    final staleConstraints = document.entities.values
        .where((item) => item.kind == CadDocumentEntityKind.constraint)
        .map((item) => item.id)
        .where((id) => !constraintIds.contains(id));
    await runtime.mutate(
      command: 'sketch.synchronize',
      remove: [...stale, ...staleConstraints],
      upsert: [
        if (activeSketch != null)
          CadDocumentEntity(
            id: activeSketch!.id,
            kind: CadDocumentEntityKind.sketch,
            data: {'sketch': activeSketch!.toJson()},
          ),
        ...sketchEntities.map((value) {
          final visual = _sketchScene.adapt(value);
          return CadDocumentEntity(
            id: value.id,
            kind: CadDocumentEntityKind.sketch,
            data: {
              'sketchEntity': value.toJson(),
              'sceneKind': visual.kind.name,
              'sceneGeometry': visual.geometry,
            },
          );
        }),
        ...constraints.map(
          (value) => CadDocumentEntity(
            id: value.id,
            kind: CadDocumentEntityKind.constraint,
            data: {'constraint': value.toJson()},
          ),
        ),
      ],
    );
    await sketchApi?.persist();
    await editorApi?.persist();
    await constraintApi?.persist();
    runtime.select(selectedSketchEntityIds);
  }
}
