import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../../core/cad_document/cad_document.dart';
import '../../core/feature_lifecycle/feature_lifecycle.dart';
import '../cad_viewport/rendering/sketch_surface_preview_builder.dart';
import '../../core/cad_kernel/io/kernel_io_models.dart';
import '../../core/cad_kernel/models/kernel_models.dart';
import '../../core/adaptive_surface/models/surface_geometry.dart';
import '../../core/adaptive_surface/continuity/surface_continuity.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';
import '../../core/geometric_kernel/linear_algebra/matrices.dart';
import '../../core/geometric_kernel/transforms/transform3.dart';
import '../../core/professional_recognition/api/professional_recognition_api.dart';
import '../../core/professional_recognition/models/professional_recognition_models.dart';
import '../../core/professional_surface/api/professional_surface_modeling_api.dart';
import '../../core/professional_surface/models/professional_surface_models.dart';
import '../../core/professional_surface/repository/professional_surface_repository.dart';
import '../../core/professional_topology/models/topological_entity.dart';
import '../../core/professional_wireframe/models/professional_curve.dart';
import '../../core/reference_engine/api/reference_api.dart';
import '../../core/reference_engine/models/reference_entity.dart';
import '../../core/reference_engine/models/reference_geometry.dart';
import '../../core/reference_engine/serialization/reference_serializer.dart';
import '../../core/sketch_constraints/api/constraint_api.dart';
import '../../core/sketch_constraints/integration/constraint_factory.dart';
import '../../core/sketch_constraints/models/constraint_models.dart';
import '../../core/sketch_editor/api/sketch_editor_api.dart';
import '../../core/sketch_editor/integration/editor_factory.dart';
import '../../core/sketch_editor/inferencing/sketch_inference_engine.dart';
import '../../core/sketch_editor/health/sketch_health_analyzer.dart';
import '../../core/sketch_editor/models/editor_models.dart';
import '../../core/sketch_editor/snapping/editor_snapping.dart';
import '../../core/sketch_engine/api/sketch_engine_api.dart';
import '../../core/sketch_engine/entities/sketch_entities.dart'
    hide ReferenceGeometry;
import '../../core/sketch_engine/history/sketch_history.dart';
import '../../core/sketch_engine/integration/sketch_factory.dart';
import '../../core/sketch_engine/models/sketch_models.dart';
import '../../core/smart_reference/models/smart_reference_models.dart';
import '../../core/smart_regions/api/smart_regions_api.dart';
import '../../core/smart_regions/models/geometry.dart';
import '../../core/surface_recognition/models/surface_recognition_models.dart'
    as region_recognition;
import '../../core/surface_recognition/segmentation/region_growing.dart';
import '../../core/surface_generation/api/surface_generation_api.dart';
import '../../core/surface_generation/integration/surface_generation_factory.dart';
import '../../core/surface_generation/models/surface_generation_models.dart';
import '../../core/surface_intelligence/api/surface_api.dart';
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
import 'selection/section_manager.dart';
import 'selection/geometry_selection_manager.dart';
import '../runtime/cad_runtime.dart';
import '../runtime/world_coordinate_system.dart';

enum RecognitionDecision { pending, accepted, rejected }

enum SketchSurfaceStage {
  idle,
  referenceReady,
  sketchActive,
  sketchFinished,
  surfacePreview,
  surfaceGenerated,
}

enum ManualTransformMode { move, rotate, scale, align }

enum TransformDisposition { original, workingCopy }

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
  Map<String, dynamic>? get professionalSurfaceAnalysis =>
      runtime.read('surface.analysis');
  List<String> get professionalSurfaceValidation =>
      runtime.read<List<String>>('surface.validation') ?? const [];
  bool get professionalSurfaceValidationCompleted =>
      runtime.read<bool>('surface.validation.completed') ?? false;
  Map<String, dynamic>? get professionalSurfaceOperationReport =>
      runtime.read<Map<String, dynamic>>('surface.operationReport');
  ProfessionalSurfaceDefinition? get selectedProfessionalSurface {
    final document = runtime.document;
    if (document == null || professionalSurfaceApi == null) return null;
    for (final id in runtime.selection) {
      final data = document.entities[id]?.data['professionalSurface'];
      if (data is Map) {
        return ProfessionalSurfaceDefinition.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    }
    return null;
  }

  ReferenceEntity? get activeReference => runtime.read('reference.active');
  set activeReference(ReferenceEntity? value) =>
      runtime.write('reference.active', value);
  PlaneGeometry? get activeSketchPlane =>
      activeReference?.geometry is PlaneGeometry
      ? activeReference!.geometry as PlaneGeometry
      : runtime.read<PlaneGeometry>('sketch.selectedPlane');
  String? get activeSketchPlaneId => activeReference?.geometry is PlaneGeometry
      ? activeReference!.id
      : runtime.read<String>('sketch.selectedPlaneId');
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
  bool get lineCommandActive =>
      runtime.read<bool>('sketch.line.active') ?? false;
  bool get circleCommandActive =>
      runtime.read<bool>('sketch.circle.active') ?? false;
  bool get arcCommandActive => runtime.read<bool>('sketch.arc.active') ?? false;
  bool get sketchCreationCommandActive =>
      lineCommandActive || circleCommandActive || arcCommandActive;
  bool get sketchEditingCommandActive =>
      runtime.read<bool>('sketch.edit.active') ?? false;
  double get sketchEditingValue =>
      runtime.read<double>('sketch.edit.value') ?? 1;
  bool get sketchFilletAutoTrim =>
      runtime.read<bool>('sketch.edit.autoTrim') ?? true;
  SketchCircleMode get circleMode =>
      runtime.read<SketchCircleMode>('sketch.circle.mode') ??
      SketchCircleMode.centerRadius;
  SketchVector? get circleCursor => runtime.read('sketch.circle.cursor');
  EditorSnapType? get circleSnapType => runtime.read('sketch.circle.snapType');
  SketchArcMode get arcMode =>
      runtime.read<SketchArcMode>('sketch.arc.mode') ?? SketchArcMode.center;
  SketchVector? get arcCursor => runtime.read('sketch.arc.cursor');
  EditorSnapType? get arcSnapType => runtime.read('sketch.arc.snapType');
  ({double radius, double startDegrees, double endDegrees, double length})?
  get arcHud {
    if (!arcCommandActive || arcCursor == null) return null;
    final definition = professionalArcDefinition(arcMode, [
      ...previewPoints,
      arcCursor!,
    ]);
    if (definition == null) return null;
    final sweep = (definition.endAngle - definition.startAngle).abs();
    return (
      radius: definition.radius,
      startDegrees: definition.startAngle * 180 / math.pi,
      endDegrees: definition.endAngle * 180 / math.pi,
      length: definition.radius * sweep,
    );
  }

  ({double x, double y, double radius, double diameter})? get circleHud {
    if (!circleCommandActive || circleCursor == null) return null;
    final definition = professionalCircleDefinition(circleMode, [
      ...previewPoints,
      circleCursor!,
    ]);
    if (definition == null) return null;
    return (
      x: definition.center.x,
      y: definition.center.y,
      radius: definition.radius,
      diameter: definition.radius * 2,
    );
  }

  SketchVector? get lineCursor => runtime.read('sketch.line.cursor');
  EditorSnapType? get lineSnapType => runtime.read('sketch.line.snapType');
  SketchInference? get activeSketchInference =>
      runtime.read<SketchInference>('sketch.inference');
  Offset? get sketchInferenceCursor =>
      runtime.read<Offset>('sketch.inference.cursor');
  final SketchInferenceEngine _sketchInference = const SketchInferenceEngine();
  final SketchHealthAnalyzer _sketchHealthAnalyzer =
      const SketchHealthAnalyzer();
  SketchHealthReport get sketchHealth =>
      _sketchHealthAnalyzer.analyze(sketchEntities);
  SketchHealthReport healthForSketch(String sketchId) {
    final api = sketchApi;
    if (api == null) {
      return const SketchHealthReport(issues: [], closedProfile: false);
    }
    final sketch = api.sketches
        .where((item) => item.id == sketchId)
        .firstOrNull;
    if (sketch == null) {
      return const SketchHealthReport(issues: [], closedProfile: false);
    }
    return _sketchHealthAnalyzer.analyze(
      sketch.entityIds.map(api.entity).whereType<SketchEntity>(),
    );
  }

  bool get sketchReadyForSurface => sketchHealth.readyForSurface;
  String get sketchSurfaceBlockReason {
    final health = sketchHealth;
    if (!health.closedProfile) return 'The Sketch contains an open profile.';
    if (health.hasGaps) {
      return 'Close the detected gaps before creating a surface.';
    }
    if (health.hasDuplicates) {
      return 'Remove duplicate or overlapping geometry.';
    }
    if (health.hasSelfIntersections) return 'Resolve self intersections.';
    if (health.hasTinyGeometry) return 'Remove or repair tiny geometry.';
    if (health.hasOpenEnds) return 'Connect the loose endpoints.';
    return 'Sketch is ready for a surface.';
  }

  ({double x, double y, double length, double angle})? get lineHud {
    final start = previewPoints.firstOrNull;
    final cursor = lineCursor;
    if (!lineCommandActive || start == null || cursor == null) return null;
    final dx = cursor.x - start.x;
    final dy = cursor.y - start.y;
    return (
      x: cursor.x,
      y: cursor.y,
      length: math.sqrt(dx * dx + dy * dy),
      angle: math.atan2(dy, dx) * 180 / math.pi,
    );
  }

  Set<String> get selectedSketchEntityIds =>
      runtime.readOrCreate('sketch.selectedIds', () => <String>{});
  Set<String> get selectedConstraintIds =>
      runtime.readOrCreate('sketch.selectedConstraintIds', () => <String>{});
  final ReferenceApi _referenceApi;
  final SmartRegionsApi _smartRegionsApi;
  final ReferenceSceneAdapter _referenceScene = const ReferenceSceneAdapter();
  final SketchSceneAdapter _sketchScene = const SketchSceneAdapter();
  final SurfaceSceneAdapter _surfaceScene = const SurfaceSceneAdapter();
  final SketchSurfacePreviewBuilder _sketchSurfacePreviewBuilder =
      const SketchSurfacePreviewBuilder();
  bool get surfacePreviewActive =>
      runtime.read<bool>('sketch.surfacePreview.active') ?? false;
  final ViewportPickingController _viewportPicking =
      ViewportPickingController();
  SectionManager get sections => SectionManager(runtime);

  CadDocumentEntity? get selectedSection {
    final document = runtime.document;
    if (document == null) return null;
    for (final id in runtime.selection) {
      final entity = document.entities[id];
      if (entity?.kind == CadDocumentEntityKind.section) return entity;
    }
    return null;
  }

  CadDocumentEntity? get selectedOrActiveSketchSourceSection {
    final selected = selectedSection;
    if (selected != null) return selected;
    final sourceId = activeSketch?.metadata['sourceSectionId'] as String?;
    if (sourceId == null) return null;
    final source = runtime.document?.entities[sourceId];
    return source?.kind == CadDocumentEntityKind.section ? source : null;
  }

  void selectSketch(String id) {
    var sketch = sketchApi?.sketches.where((item) => item.id == id).firstOrNull;
    final persisted = runtime.document?.entities[id]?.data['sketch'];
    if (sketch == null && persisted is Map) {
      sketch = Sketch.fromJson(Map<String, dynamic>.from(persisted));
    }
    if (sketch == null) throw StateError('Unknown Sketch: $id');
    activeSketch = sketch;
    runtime.select({id});
    notifyListeners();
  }

  Future<void> reopenSketchForEditing(String id) async {
    final api = sketchApi ?? (throw StateError('SketchEngine is unavailable.'));
    selectSketch(id);
    cancelSketchCommand();
    api.openSketch(id);
    stage = SketchSurfaceStage.sketchActive;
    selectedSketchEntityIds.clear();
    selectedConstraintIds.clear();
    runtime.select({id});
    await _synchronizeSketchScene();
    notifyListeners();
  }

  List<String> get g106bCertificationResults =>
      runtime.read<List<String>>('sketch.g106bCertification') ?? const [];

  Future<void> runG106BCertification() async {
    final api = sketchApi ?? (throw StateError('SketchEngine is unavailable.'));
    final editor =
        editorApi ?? (throw StateError('SketchEditor is unavailable.'));
    final sketch = api.createSketch(
      'G-106B Certification',
      plane: SketchPlane(type: SketchPlaneType.xy),
      coordinates: const SketchCoordinateSystem(),
    );
    sketch.metadata.addAll({
      'certification': 'G-106B',
      'associationState': 'detached',
      'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    api.openSketch(sketch.id);
    activeSketch = sketch;
    final results = <String>[];

    void edit(
      SketchToolType tool,
      Iterable<String> ids, {
      SketchVector? delta,
      double value = 1,
      Map<String, dynamic> parameters = const {},
    }) {
      editor.preview(tool, const []);
      editor.edit(
        tool,
        ids,
        delta: delta,
        value: value,
        parameters: parameters,
      );
      results.add('${tool.name}: OK');
    }

    final transformed = api.builders.line.build(
      const SketchVector(-18, 8),
      const SketchVector(-12, 8),
    );
    edit(SketchToolType.move, [
      transformed.id,
    ], delta: const SketchVector(1, 1));
    edit(
      SketchToolType.rotate,
      [transformed.id],
      value: math.pi / 12,
      parameters: {'center': const SketchVector(-17, 9).toJson()},
    );
    edit(
      SketchToolType.scale,
      [transformed.id],
      value: 1.25,
      parameters: {'center': const SketchVector(-17, 9).toJson()},
    );
    edit(
      SketchToolType.mirror,
      [transformed.id],
      parameters: {
        'axisStart': const SketchVector(0, 0).toJson(),
        'axisEnd': const SketchVector(1, 0).toJson(),
      },
    );

    final offset = api.builders.circle.build(const SketchVector(-8, 8), 2);
    edit(SketchToolType.offset, [offset.id], value: 1);

    final trimmed = api.builders.line.build(
      const SketchVector(0, 8),
      const SketchVector(8, 8),
    );
    edit(
      SketchToolType.trim,
      [trimmed.id],
      parameters: {'point': const SketchVector(2, 10).toJson()},
    );
    edit(
      SketchToolType.extend,
      [trimmed.id],
      parameters: {'point': const SketchVector(10, 6).toJson()},
    );

    final broken = api.builders.line.build(
      const SketchVector(-18, 2),
      const SketchVector(-10, 2),
    );
    edit(
      SketchToolType.breakEntity,
      [broken.id],
      parameters: {'point': const SketchVector(-14, 3).toJson()},
    );
    final split = api.builders.circle.build(const SketchVector(-5, 2), 3);
    edit(
      SketchToolType.split,
      [split.id],
      parameters: {'point': const SketchVector(-2, 2).toJson()},
    );

    final joinA = api.builders.line.build(
      const SketchVector(2, 2),
      const SketchVector(5, 2),
    );
    final joinB = api.builders.line.build(
      const SketchVector(5, 2),
      const SketchVector(9, 2),
    );
    edit(SketchToolType.join, [joinA.id, joinB.id]);

    final filletA = api.builders.line.build(
      const SketchVector(12, 1),
      const SketchVector(18, 1),
    );
    final filletB = api.builders.line.build(
      const SketchVector(12, 1),
      const SketchVector(12, 7),
    );
    edit(SketchToolType.fillet, [filletA.id, filletB.id], value: 1);
    final chamferA = api.builders.line.build(
      const SketchVector(12, 10),
      const SketchVector(18, 10),
    );
    final chamferB = api.builders.line.build(
      const SketchVector(12, 10),
      const SketchVector(12, 16),
    );
    edit(SketchToolType.chamfer, [chamferA.id, chamferB.id], value: 1);

    if (!editor.undo() || !editor.redo()) {
      throw StateError('G-106B Undo/Redo certification failed.');
    }
    results.add('undo: OK');
    results.add('redo: OK');
    sketch.metadata.addAll({
      'entityCount': sketch.entityIds.length,
      'certificationResults': results,
      'certifiedAt': DateTime.now().toUtc().toIso8601String(),
    });
    runtime.write('sketch.g106bCertification', List<String>.of(results));
    stage = SketchSurfaceStage.sketchFinished;
    await _synchronizeSketchScene();
    runtime.select({sketch.id});
    notifyListeners();
  }

  Future<void> createSection() async {
    final plane = activeSketchPlane;
    final planeId = activeSketchPlaneId;
    if (plane == null || planeId == null) {
      throw StateError('Select a plane in Explorer before creating a Section.');
    }
    await sections.create(
      planeId: planeId,
      origin: Vector3.fromJson(plane.origin.toJson()),
      normal: Vector3.fromJson(plane.normal.toJson()),
    );
    notifyListeners();
  }

  Future<void> createMultipleSections({
    int count = 5,
    double spacing = 5,
  }) async {
    final plane = activeSketchPlane;
    final planeId = activeSketchPlaneId;
    if (plane == null || planeId == null) {
      throw StateError('Select a plane in Explorer before creating Sections.');
    }
    await sections.createMultiple(
      planeId: planeId,
      origin: Vector3.fromJson(plane.origin.toJson()),
      normal: Vector3.fromJson(plane.normal.toJson()),
      count: count,
      spacing: spacing,
    );
    notifyListeners();
  }

  Future<void> createSectionsBySelectedAxis({
    int count = 5,
    double spacing = 5,
  }) async {
    final selected = runtime.selection
        .map(runtime.scene.find)
        .whereType<CadSceneEntity>()
        .where((entity) => entity.kind == CadSceneEntityKind.axis)
        .firstOrNull;
    if (selected == null) throw StateError('Select an axis in Explorer first.');
    final origin = Vector3.fromJson(selected.geometry['origin'] as List);
    final direction = Vector3.fromJson(selected.geometry['direction'] as List);
    await sections.createMultiple(
      planeId: selected.id,
      origin: origin,
      normal: direction,
      count: count,
      spacing: spacing,
    );
    notifyListeners();
  }

  Future<void> moveSelectedSection(double offset) async {
    final section =
        selectedSection ??
        (throw StateError('Select a Section before moving it.'));
    await sections.updateOffset(section.id, offset);
    runtime.select({section.id});
    notifyListeners();
  }

  Future<void> createSketchFromSelectedSection({
    bool convertToSpline = false,
    double tolerance = 0.05,
  }) async {
    final section =
        selectedOrActiveSketchSourceSection ??
        (throw StateError('Select a Section before creating a Sketch.'));
    final api =
        sketchApi ??
        (throw StateError('The project SketchEngine is unavailable.'));
    final definition = Map<String, dynamic>.from(
      section.data['section'] as Map,
    );
    final origin = Vector3.fromJson(definition['origin'] as List);
    final normal = Vector3.fromJson(definition['normal'] as List).normalized;
    final xAxis = normal
        .cross(
          normal.z.abs() < .9 ? const Vector3(0, 0, 1) : const Vector3(0, 1, 0),
        )
        .normalized;
    final yAxis = normal.cross(xAxis).normalized;
    SketchVector vector(Vector3 value) =>
        SketchVector(value.x, value.y, value.z);
    final chains = _orderedSectionChains(definition['segments'] as List);
    if (chains.isEmpty) {
      throw StateError('The selected Section has no connected segments.');
    }
    final sketch = api.createSketch(
      'Sketch ${(api.sketches.length + 1).toString().padLeft(3, '0')}',
      plane: SketchPlane(
        type: SketchPlaneType.faceReference,
        parameters: {
          'referenceId': definition['planeId'],
          'sectionId': section.id,
          'origin': origin.toJson(),
          'normal': normal.toJson(),
          'xDirection': xAxis.toJson(),
        },
      ),
      coordinates: SketchCoordinateSystem(
        origin: vector(origin),
        xAxis: vector(xAxis),
        yAxis: vector(yAxis),
        normal: vector(normal),
      ),
    );
    sketch.metadata.addAll({
      'sourceSectionId': section.id,
      'associative': true,
      'conversion': convertToSpline ? 'spline' : 'polyline',
      'tolerance': tolerance,
      'associationState': 'current',
      'sourceSectionRevision': section.data['revision'] ?? 1,
      'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    api.openSketch(sketch.id);
    var sourcePoints = 0;
    var sourceSegments = 0;
    var maximumError = 0.0;
    var errorSum = 0.0;
    var errorSamples = 0;
    for (final chain in chains) {
      final local = chain
          .map((point) => sketch.coordinates.globalToLocal(vector(point)))
          .toList();
      sourcePoints += local.length;
      sourceSegments += math.max(0, local.length - 1);
      if (convertToSpline) {
        final fit = _fitSectionSpline(local, tolerance);
        final spline = api.builders.spline.build(fit.controlPoints);
        spline.parameters.addAll({
          'sampledPoints': fit.sampledPoints
              .map((point) => point.toJson())
              .toList(),
          'degree': math.min(3, fit.controlPoints.length - 1),
          'tolerance': tolerance,
          'maximumError': fit.maximumError,
          'meanError': fit.meanError,
          'sourcePointCount': local.length,
        });
        maximumError = math.max(maximumError, fit.maximumError);
        errorSum += fit.meanError * local.length;
        errorSamples += local.length;
      } else {
        for (var index = 0; index + 1 < local.length; index++) {
          api.builders.line.build(local[index], local[index + 1]);
        }
      }
    }
    sketch.metadata.addAll({
      'pointCount': sourcePoints,
      'segmentCount': sourceSegments,
      'entityCount': sketch.entityIds.length,
      'maximumError': maximumError,
      'meanError': errorSamples == 0 ? 0.0 : errorSum / errorSamples,
      'fittingParameters': {
        'method': convertToSpline
            ? 'centripetalCatmullRomAdaptive'
            : 'sectionPolyline',
        'tolerance': tolerance,
      },
    });
    activeSketch = sketch;
    stage = SketchSurfaceStage.sketchFinished;
    await _synchronizeSketchScene();
    runtime.select({sketch.id});
    notifyListeners();
  }

  _SectionSplineFit _fitSectionSpline(
    List<SketchVector> source,
    double tolerance,
  ) {
    if (source.length < 2) {
      throw StateError('A spline requires at least two Section points.');
    }
    var epsilon = math.max(tolerance, 1e-9);
    var controls = source;
    var samples = source;
    var errors = const <double>[];
    for (var attempt = 0; attempt < 10; attempt++) {
      controls = _simplifySketchPoints(source, epsilon);
      if (controls.length < 4 && source.length >= 4) {
        controls = [
          source.first,
          source[source.length ~/ 3],
          source[source.length * 2 ~/ 3],
          source.last,
        ];
      }
      samples = _sampleCentripetalSpline(controls);
      errors = source
          .map((point) => _distanceToSketchPolyline(point, samples))
          .toList();
      if (errors.isEmpty || errors.reduce(math.max) <= tolerance) break;
      epsilon *= .5;
    }
    final maximum = errors.isEmpty ? 0.0 : errors.reduce(math.max);
    final mean = errors.isEmpty
        ? 0.0
        : errors.reduce((a, b) => a + b) / errors.length;
    return _SectionSplineFit(controls, samples, maximum, mean);
  }

  List<SketchVector> _simplifySketchPoints(
    List<SketchVector> points,
    double tolerance,
  ) {
    if (points.length <= 2) return List.of(points);
    var maximum = 0.0, split = 0;
    for (var index = 1; index + 1 < points.length; index++) {
      final distance = _distanceToSketchSegment(
        points[index],
        points.first,
        points.last,
      );
      if (distance > maximum) {
        maximum = distance;
        split = index;
      }
    }
    if (maximum <= tolerance) return [points.first, points.last];
    final left = _simplifySketchPoints(points.sublist(0, split + 1), tolerance);
    final right = _simplifySketchPoints(points.sublist(split), tolerance);
    return [...left.take(left.length - 1), ...right];
  }

  List<SketchVector> _sampleCentripetalSpline(List<SketchVector> controls) {
    if (controls.length < 3) return List.of(controls);
    final output = <SketchVector>[controls.first];
    for (var index = 0; index + 1 < controls.length; index++) {
      final p0 = controls[math.max(0, index - 1)];
      final p1 = controls[index];
      final p2 = controls[index + 1];
      final p3 = controls[math.min(controls.length - 1, index + 2)];
      for (var step = 1; step <= 16; step++) {
        final t = step / 16, t2 = t * t, t3 = t2 * t;
        SketchVector axis(double Function(SketchVector) value) => SketchVector(
          .5 *
              ((2 * value(p1)) +
                  (-value(p0) + value(p2)) * t +
                  (2 * value(p0) - 5 * value(p1) + 4 * value(p2) - value(p3)) *
                      t2 +
                  (-value(p0) + 3 * value(p1) - 3 * value(p2) + value(p3)) *
                      t3),
          0,
        );
        final x = axis((point) => point.x).x;
        final y = axis((point) => point.y).x;
        final z = axis((point) => point.z).x;
        output.add(SketchVector(x, y, z));
      }
    }
    return output;
  }

  double _distanceToSketchPolyline(
    SketchVector point,
    List<SketchVector> polyline,
  ) {
    var minimum = double.infinity;
    for (var index = 0; index + 1 < polyline.length; index++) {
      minimum = math.min(
        minimum,
        _distanceToSketchSegment(point, polyline[index], polyline[index + 1]),
      );
    }
    return minimum.isFinite ? minimum : 0;
  }

  double _distanceToSketchSegment(
    SketchVector point,
    SketchVector start,
    SketchVector end,
  ) {
    final segment = end - start;
    final lengthSquared = segment.dot(segment);
    if (lengthSquared <= 1e-24) {
      final delta = point - start;
      return math.sqrt(delta.dot(delta));
    }
    final t = ((point - start).dot(segment) / lengthSquared)
        .clamp(0.0, 1.0)
        .toDouble();
    final delta = point - (start + segment.scale(t));
    return math.sqrt(delta.dot(delta));
  }

  List<List<Vector3>> _orderedSectionChains(List<dynamic> rawSegments) {
    final segments = rawSegments
        .map(
          (raw) => (raw as List)
              .map((point) => Vector3.fromJson(point as List))
              .toList(),
        )
        .where((segment) => segment.length == 2)
        .toList();
    if (segments.isEmpty) return const [];
    final scale = segments
        .expand((segment) => segment)
        .fold<double>(
          1,
          (value, point) => math.max(
            value,
            math.max(point.x.abs(), math.max(point.y.abs(), point.z.abs())),
          ),
        );
    final tolerance = math.max(1e-9, scale * 1e-9);
    String key(Vector3 point) =>
        '${(point.x / tolerance).round()}:${(point.y / tolerance).round()}:${(point.z / tolerance).round()}';
    final remaining = List<List<Vector3>>.from(segments);
    final output = <List<Vector3>>[];
    while (remaining.isNotEmpty) {
      final first = remaining.removeLast();
      final chain = <Vector3>[first[0], first[1]];
      var extended = true;
      while (extended) {
        extended = false;
        for (var index = 0; index < remaining.length; index++) {
          final candidate = remaining[index];
          if (key(candidate[0]) == key(chain.last)) {
            chain.add(candidate[1]);
          } else if (key(candidate[1]) == key(chain.last)) {
            chain.add(candidate[0]);
          } else {
            continue;
          }
          remaining.removeAt(index);
          extended = true;
          break;
        }
      }
      output.add(chain);
    }
    return output;
  }

  Future<void> updateActiveSketchFromSourceSection() async {
    final sketch =
        activeSketch ??
        (throw StateError('Select an associated Sketch first.'));
    final sourceId = sketch.metadata['sourceSectionId'] as String?;
    if (sourceId == null) throw StateError('The Sketch is not associative.');
    final source = runtime.document?.entities[sourceId];
    if (source?.kind != CadDocumentEntityKind.section) {
      throw StateError('The source Section is unavailable.');
    }
    final api = sketchApi!;
    api.openSketch(sketch.id);
    for (final id in List<String>.of(sketch.entityIds)) {
      api.deleteEntity(id);
    }
    final definition = Map<String, dynamic>.from(
      source!.data['section'] as Map,
    );
    final chains = _orderedSectionChains(definition['segments'] as List);
    final spline = sketch.metadata['conversion'] == 'spline';
    final tolerance =
        (sketch.metadata['tolerance'] as num?)?.toDouble() ?? 0.05;
    var points = 0, segments = 0, samples = 0;
    var maximumError = 0.0, weightedError = 0.0;
    for (final chain in chains) {
      final local = chain
          .map(
            (point) => sketch.coordinates.globalToLocal(
              SketchVector(point.x, point.y, point.z),
            ),
          )
          .toList();
      points += local.length;
      segments += math.max(0, local.length - 1);
      if (spline) {
        final fit = _fitSectionSpline(local, tolerance);
        final entity = api.builders.spline.build(fit.controlPoints);
        entity.parameters.addAll({
          'sampledPoints': fit.sampledPoints
              .map((point) => point.toJson())
              .toList(),
          'degree': math.min(3, fit.controlPoints.length - 1),
          'tolerance': tolerance,
          'maximumError': fit.maximumError,
          'meanError': fit.meanError,
          'sourcePointCount': local.length,
        });
        maximumError = math.max(maximumError, fit.maximumError);
        weightedError += fit.meanError * local.length;
        samples += local.length;
      } else {
        for (var index = 0; index + 1 < local.length; index++) {
          api.builders.line.build(local[index], local[index + 1]);
        }
      }
    }
    sketch.version++;
    sketch.metadata.addAll({
      'associationState': 'current',
      'sourceSectionRevision': source.data['revision'] ?? 1,
      'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
      'pointCount': points,
      'segmentCount': segments,
      'entityCount': sketch.entityIds.length,
      'maximumError': maximumError,
      'meanError': samples == 0 ? 0.0 : weightedError / samples,
    });
    await _synchronizeSketchScene();
    runtime.select({sketch.id});
    notifyListeners();
  }

  Future<void> toggleSourceSectionVisibility() async {
    final sketch = activeSketch;
    final sourceId = sketch?.metadata['sourceSectionId'] as String?;
    final section =
        selectedSection ??
        (sourceId == null ? null : runtime.document?.entities[sourceId]);
    if (section == null) throw StateError('No source Section is available.');
    final visible = section.data['sceneVisible'] as bool? ?? true;
    await sections.visibility(section.id, !visible);
    notifyListeners();
  }

  Future<void> toggleActiveSketchVisibility() async {
    final sketch = activeSketch ?? (throw StateError('No active Sketch.'));
    final visible = sketch.metadata['visible'] as bool? ?? true;
    sketch.metadata['visible'] = !visible;
    final ids = [sketch.id, ...sketch.entityIds];
    for (final id in ids) {
      await runtime.setEntityVisibility(id, !visible);
    }
    await sketchApi?.persist();
    notifyListeners();
  }

  void previewBestFitSpline(double tolerance) {
    final section =
        selectedOrActiveSketchSourceSection ??
        (throw StateError('Select a Section before previewing a Spline.'));
    final definition = Map<String, dynamic>.from(
      section.data['section'] as Map,
    );
    final origin = Vector3.fromJson(definition['origin'] as List);
    final normal = Vector3.fromJson(definition['normal'] as List).normalized;
    final xAxis = normal
        .cross(
          normal.z.abs() < .9 ? const Vector3(0, 0, 1) : const Vector3(0, 1, 0),
        )
        .normalized;
    final yAxis = normal.cross(xAxis).normalized;
    final points = <List<double>>[];
    for (final chain in _orderedSectionChains(definition['segments'] as List)) {
      final local = chain
          .map(
            (point) => SketchVector(
              (point - origin).dot(xAxis),
              (point - origin).dot(yAxis),
            ),
          )
          .toList();
      final fit = _fitSectionSpline(local, tolerance);
      points.addAll(
        fit.sampledPoints.map((point) {
          final global = origin + xAxis * point.x + yAxis * point.y;
          return global.toJson();
        }),
      );
    }
    runtime.showTransient(
      CadSceneEntity(
        id: 'section-spline-preview',
        kind: CadSceneEntityKind.preview,
        transparent: true,
        geometry: {
          'points': points,
          'displayColor': 'previewOrange',
          'strokeWidth': 3.0,
        },
      ),
    );
    notifyListeners();
  }

  void clearBestFitSplinePreview() {
    runtime.hideTransient('section-spline-preview');
    notifyListeners();
  }

  String? get alignmentTarget => runtime.read('alignment.target');
  set alignmentTarget(String? value) =>
      runtime.write('alignment.target', value);
  Transform3? get alignmentTransform => runtime.read('alignment.transform');
  set alignmentTransform(Transform3? value) =>
      runtime.write('alignment.transform', value);

  bool get canAlign => activeReference?.geometry is PlaneGeometry;

  ManualTransformMode? get manualTransformMode =>
      runtime.read('transform.mode');
  Transform3? get manualTransformPreview => runtime.read('transform.preview');
  Set<String> get manualTransformTargets =>
      runtime.read<Set<String>>('transform.targets') ?? const {};
  TransformDisposition? get transformDisposition =>
      runtime.read('transform.disposition');

  void chooseTransformDisposition(TransformDisposition? value) {
    cancelManualTransform(notify: false);
    runtime.write('transform.disposition', value);
    notifyListeners();
  }

  bool get canTransformSelection => runtime.selection.any((id) {
    final entity = runtime.document?.entities[id];
    return entity != null &&
        entity.data['group'] != 'World Coordinate System' &&
        entity.data['deleted'] != true;
  });

  Future<void> previewManualTransform(
    ManualTransformMode mode,
    Transform3 transform,
  ) async {
    cancelManualTransform(notify: false);
    if (transformDisposition == null) {
      throw StateError(
        'Choose Transform Original or Create Working Copy before preview.',
      );
    }
    final document =
        runtime.document ??
        (throw StateError('Open a project before transforming geometry.'));
    final selected = _expandedTransformTargets(runtime.selection, document);
    if (selected.isEmpty) {
      throw StateError('Select an entity in the viewport or Explorer first.');
    }
    for (final id in selected) {
      final entity =
          document.entities[id] ??
          (throw StateError('Unknown document entity: $id'));
      if (entity.data['group'] == 'World Coordinate System') {
        throw StateError('World Coordinate System entities are protected.');
      }
      final scene = runtime.scene.find(id);
      if (scene == null) continue;
      if (entity.shape != null) {
        final preview = await runtime.previewNativeShapeTransform(
          entity.shape!,
          transform.matrix,
        );
        await runtime.showTransientShape(
          CadSceneEntity(
            id: 'transform-preview-$id',
            kind: CadSceneEntityKind.preview,
            transparent: true,
            geometry: const {'displayColor': 'previewOrange'},
          ),
          preview,
        );
        continue;
      }
      runtime.showTransient(
        CadSceneEntity(
          id: 'transform-preview-$id',
          kind: scene.kind == CadSceneEntityKind.mesh
              ? CadSceneEntityKind.preview
              : scene.kind,
          transparent: true,
          geometry: runtime.transformedSceneGeometry(entity, transform.matrix),
        ),
      );
    }
    final pivot = _selectionPivot(selected, document);
    const length = 25.0;
    for (final axis in const [
      ('x', Vector3(1, 0, 0)),
      ('y', Vector3(0, 1, 0)),
      ('z', Vector3(0, 0, 1)),
    ]) {
      runtime.showTransient(
        CadSceneEntity(
          id: 'transform-gizmo-${axis.$1}',
          kind: CadSceneEntityKind.axis,
          geometry: {
            'origin': pivot.toJson(),
            'direction': axis.$2.toJson(),
            'visualLength': length,
            'axisColor': axis.$1,
          },
        ),
      );
    }
    runtime.write('transform.mode', mode);
    runtime.write('transform.preview', transform);
    runtime.write('transform.targets', Set<String>.from(selected));
    notifyListeners();
  }

  Future<void> previewMove(Vector3 delta) => previewManualTransform(
    ManualTransformMode.move,
    Transform3.translation(delta),
  );

  Future<void> previewRotate(Vector3 axis, double degrees) {
    final pivot = _selectionPivot(
      runtime.selection,
      runtime.document ?? (throw StateError('Open a project first.')),
    );
    final rotation = Transform3.rotation(
      Quaternion.axisAngle(axis, degrees * math.pi / 180),
    );
    return previewManualTransform(
      ManualTransformMode.rotate,
      Transform3.translation(
        pivot,
      ).compose(rotation).compose(Transform3.translation(-pivot)),
    );
  }

  Future<void> previewScale(Vector3 factors) {
    if (factors.x == 0 || factors.y == 0 || factors.z == 0) {
      throw ArgumentError('Scale factors must be non-zero.');
    }
    final pivot = _selectionPivot(
      runtime.selection,
      runtime.document ?? (throw StateError('Open a project first.')),
    );
    return previewManualTransform(
      ManualTransformMode.scale,
      Transform3.translation(pivot)
          .compose(Transform3.scale(factors))
          .compose(Transform3.translation(-pivot)),
    );
  }

  Future<void> previewTransformByReference(String target) {
    final document =
        runtime.document ?? (throw StateError('Open a project first.'));
    final references = runtime.selection
        .map((id) => document.entities[id])
        .whereType<CadDocumentEntity>()
        .where((entity) => entity.kind == CadDocumentEntityKind.reference)
        .toList();
    if (references.isEmpty) {
      throw StateError('Select a point, plane, axis, or coordinate system.');
    }
    final geometry = references.first.data['sceneGeometry'];
    if (geometry is! Map) {
      throw StateError('Reference geometry is unavailable.');
    }
    final origin = _vector(geometry['origin'] ?? geometry['position']);
    Transform3 transform;
    if (target == 'Origin') {
      transform = Transform3.translation(-origin);
    } else {
      final source = _vector(geometry['normal'] ?? geometry['direction']);
      final destination = switch (target) {
        'XY' || 'Z' => const Vector3(0, 0, 1),
        'XZ' || 'Y' => const Vector3(0, 1, 0),
        'YZ' || 'X' => const Vector3(1, 0, 0),
        _ => throw StateError('Unknown reference target: $target'),
      };
      transform = Transform3.align(source, destination);
    }
    return previewManualTransform(ManualTransformMode.align, transform);
  }

  Future<void> applyManualTransform() async {
    final preview = manualTransformPreview;
    final targets = manualTransformTargets;
    if (preview == null || targets.isEmpty) {
      throw StateError('Create a transform preview before applying it.');
    }
    await runtime.applyEntityTransform(
      targets,
      preview.matrix,
      command: 'transform.${manualTransformMode!.name}',
      createCopy: transformDisposition == TransformDisposition.workingCopy,
    );
    cancelManualTransform(notify: false);
    notifyListeners();
  }

  Future<void> resetSelectedTransform() async {
    final document =
        runtime.document ?? (throw StateError('Open a project first.'));
    for (final id in runtime.selection) {
      final entity = document.entities[id];
      final raw = entity?.data['transformMatrix'];
      if (raw is! List || raw.length != 16) continue;
      final matrix = Matrix4(raw.cast<num>().map((v) => v.toDouble()).toList());
      await runtime.applyEntityTransform(
        {id},
        matrix.inverse(),
        command: 'transform.reset',
      );
    }
  }

  Future<void> undoManualTransform() async {
    cancelManualTransform(notify: false);
    await runtime.undoDocument();
    notifyListeners();
  }

  Future<void> redoManualTransform() async {
    cancelManualTransform(notify: false);
    await runtime.redoDocument();
    notifyListeners();
  }

  void cancelManualTransform({bool notify = true}) {
    for (final id in manualTransformTargets) {
      runtime.hideTransient('transform-preview-$id');
    }
    for (final axis in const ['x', 'y', 'z']) {
      runtime.hideTransient('transform-gizmo-$axis');
    }
    runtime.write<ManualTransformMode>('transform.mode', null);
    runtime.write<Transform3>('transform.preview', null);
    runtime.write<Set<String>>('transform.targets', null);
    if (notify) notifyListeners();
  }

  List<CadDocumentEntity> deletionImpact(String entityId) =>
      runtime.dependencyImpact(entityId);

  void previewDeletion(String entityId, {required bool includeDependencies}) {
    clearDeletionPreview();
    final document =
        runtime.document ??
        (throw StateError('Open a project before deleting entities.'));
    final ids = <String>{
      entityId,
      if (includeDependencies)
        ...runtime.dependencyImpact(entityId).map((item) => item.id),
    };
    runtime.write('delete.previewIds', ids);
    for (final id in ids) {
      final entity = document.entities[id];
      final scene = runtime.scene.find(id);
      if (entity == null || scene == null) continue;
      runtime.showTransient(
        CadSceneEntity(
          id: 'delete-preview-$id',
          kind: CadSceneEntityKind.preview,
          transparent: true,
          geometry: {
            ...scene.geometry,
            'displayColor': 'destructiveRed',
            'strokeWidth': 4.0,
          },
        ),
      );
    }
    notifyListeners();
  }

  void clearDeletionPreview() {
    final ids = runtime.read<Set<String>>('delete.previewIds') ?? const {};
    for (final id in ids) {
      runtime.hideTransient('delete-preview-$id');
    }
    runtime.write<Set<String>>('delete.previewIds', null);
  }

  Future<void> deleteToRecycleBin(
    String entityId, {
    required bool includeDependencies,
  }) async {
    clearDeletionPreview();
    await runtime.moveToRecycleBin(
      entityId,
      includeDependencies: includeDependencies,
    );
    notifyListeners();
  }

  Future<void> restoreDeleted(String entityId) async {
    await runtime.restoreFromRecycleBin(entityId);
    notifyListeners();
  }

  Future<void> permanentlyDelete(String entityId) async {
    await runtime.permanentlyDelete(entityId);
    notifyListeners();
  }

  Vector3 _selectionPivot(Set<String> ids, CadDocument document) {
    final points = <Vector3>[];
    for (final id in ids) {
      final geometry = document.entities[id]?.data['sceneGeometry'];
      if (geometry is! Map) continue;
      final bounds = geometry['bounds'];
      if (bounds is Map) {
        final minimum = _vector(bounds['min']);
        final maximum = _vector(bounds['max']);
        points.add((minimum + maximum) * .5);
      } else if (geometry['origin'] is List || geometry['position'] is List) {
        points.add(_vector(geometry['origin'] ?? geometry['position']));
      } else if (geometry['points'] is List &&
          (geometry['points'] as List).isNotEmpty) {
        points.add(_vector((geometry['points'] as List).first));
      }
    }
    if (points.isEmpty) return Vector3.zero;
    return points.reduce((a, b) => a + b) / points.length.toDouble();
  }

  Set<String> _expandedTransformTargets(
    Set<String> selected,
    CadDocument document,
  ) {
    final result = Set<String>.from(selected);
    var changed = true;
    while (changed) {
      changed = false;
      for (final entity in document.entities.values) {
        final sourceSection = entity.data['sourceSectionId'];
        final section = entity.data['section'];
        final meshId = section is Map ? section['meshId'] : null;
        final ownerSketch = document.entities.values.any((parent) {
          final ids = parent.data['geometricEntities'];
          return result.contains(parent.id) &&
              ids is List &&
              ids.contains(entity.id);
        });
        if ((sourceSection is String && result.contains(sourceSection)) ||
            (meshId is String && result.contains(meshId)) ||
            ownerSketch) {
          changed = result.add(entity.id) || changed;
        }
      }
    }
    return result;
  }

  Vector3 _vector(Object? value) {
    if (value is! List || value.length < 3) {
      throw StateError('Reference does not contain a valid 3D vector.');
    }
    return Vector3(
      (value[0] as num).toDouble(),
      (value[1] as num).toDouble(),
      (value[2] as num).toDouble(),
    );
  }

  void previewAlignment(String target) {
    final plane = activeReference?.geometry;
    final meshEntities = runtime.document?.entities.values
        .where((item) => item.kind == CadDocumentEntityKind.import)
        .toList();
    final meshEntity = meshEntities == null || meshEntities.isEmpty
        ? null
        : meshEntities.last;
    if (plane is! PlaneGeometry || meshEntity == null) {
      throw StateError('Create an approved plane before alignment.');
    }
    final targetNormal = switch (target) {
      'XY' => const Vector3(0, 0, 1),
      'XZ' => const Vector3(0, 1, 0),
      'YZ' => const Vector3(1, 0, 0),
      _ => throw StateError('Unknown alignment target: $target'),
    };
    Vector3 vector(List<double> value) => Vector3(value[0], value[1], value[2]);
    final origin = vector(plane.origin.toJson());
    final rotation = Transform3.align(
      vector(plane.normal.toJson()),
      targetNormal,
    );
    final transform = rotation.compose(Transform3.translation(-origin));
    alignmentTarget = target;
    alignmentTransform = transform;
    final geometry = meshEntity.data['sceneGeometry'];
    if (geometry is Map && geometry['nodes'] is List) {
      final nodes = (geometry['nodes'] as List).cast<num>();
      final output = <double>[];
      for (var index = 0; index + 2 < nodes.length; index += 3) {
        final point = transform.apply(
          Vector3(
            nodes[index].toDouble(),
            nodes[index + 1].toDouble(),
            nodes[index + 2].toDouble(),
          ),
        );
        output.addAll([point.x, point.y, point.z]);
      }
      runtime.showTransient(
        CadSceneEntity(
          id: 'alignment-preview',
          kind: CadSceneEntityKind.preview,
          transparent: true,
          geometry: {...Map<String, dynamic>.from(geometry), 'nodes': output},
        ),
      );
    }
    notifyListeners();
  }

  Future<void> applyAlignment() async {
    final transform = alignmentTransform;
    if (transform == null) throw StateError('Preview an alignment first.');
    final references = await _referenceApi.list(runtime.document!.projectId);
    for (final reference in references) {
      final updated = reference.copyWith(
        geometry: _transformReferenceGeometry(reference.geometry, transform),
        updatedAt: DateTime.now().toUtc(),
      );
      await _referenceApi.delete(reference);
      await _referenceApi.restore(updated);
      if (activeReference?.id == updated.id) activeReference = updated;
    }
    await runtime.applyAlignmentTransform(transform.matrix);
    runtime.hideTransient('alignment-preview');
    alignmentTransform = null;
    notifyListeners();
  }

  ReferenceGeometry _transformReferenceGeometry(
    ReferenceGeometry geometry,
    Transform3 transform,
  ) {
    Vec3 point(Vec3 value) {
      final result = transform.apply(Vector3(value.x, value.y, value.z));
      return Vec3(result.x, result.y, result.z);
    }

    Vec3 direction(Vec3 value) {
      final origin = transform.apply(Vector3.zero);
      final result = transform.apply(Vector3(value.x, value.y, value.z));
      final normalized = (result - origin).normalized;
      return Vec3(normalized.x, normalized.y, normalized.z);
    }

    return switch (geometry) {
      PlaneGeometry() => PlaneGeometry(
        point(geometry.origin),
        direction(geometry.normal),
        xDirection: geometry.xDirection == null
            ? null
            : direction(geometry.xDirection!),
      ),
      AxisGeometry() => AxisGeometry(
        point(geometry.origin),
        direction(geometry.direction),
      ),
      PointGeometry() => PointGeometry(point(geometry.position)),
      CoordinateSystemGeometry() => CoordinateSystemGeometry(
        point(geometry.origin),
        direction(geometry.xAxis),
        direction(geometry.yAxis),
        direction(geometry.zAxis),
      ),
      CurveGeometry() => CurveGeometry(
        geometry.points.map(point).toList(),
        closed: geometry.closed,
      ),
    };
  }

  void cancelAlignment() {
    runtime.hideTransient('alignment-preview');
    alignmentTransform = null;
    alignmentTarget = null;
    notifyListeners();
  }

  void selectDocumentPlane(String entityId) {
    selectSketchSupport(entityId);
  }

  /// Selects a geometric Sketch support. No Mesh is consulted or required.
  /// Planar Faces and Surfaces participate by publishing `sketchSupport` (or
  /// planar `sceneGeometry`) through their document entity data.
  void selectSketchSupport(String entityId) {
    final entity = runtime.document?.entities[entityId];
    if (entity == null ||
        !{
          CadDocumentEntityKind.reference,
          CadDocumentEntityKind.face,
          CadDocumentEntityKind.surface,
        }.contains(entity.kind)) {
      return;
    }
    final raw = entity.data['sketchSupport'] ?? entity.data['sceneGeometry'];
    if (raw is! Map || raw['type'] != 'plane') return;
    runtime.write(
      'sketch.selectedPlane',
      geometryFromJson(Map<String, dynamic>.from(raw)) as PlaneGeometry,
    );
    runtime.write('sketch.selectedPlaneId', entityId);
    stage = SketchSurfaceStage.referenceReady;
    runtime.select({entityId});
    notifyListeners();
  }

  /// Selects one of the three immutable world planes as a Sketch support.
  /// These planes exist in every project, including projects without imports.
  void selectWorldSketchPlane(SketchPlaneType type) {
    final document = runtime.document;
    if (document == null) throw StateError('Open a project first.');
    final suffix = switch (type) {
      SketchPlaneType.xy => 'xy-plane',
      SketchPlaneType.yz => 'yz-plane',
      SketchPlaneType.zx => 'xz-plane',
      _ => throw ArgumentError.value(type, 'type', 'Use XY, YZ or ZX.'),
    };
    selectSketchSupport(
      '${WorldCoordinateSystem.prefix(document.projectId)}$suffix',
    );
  }

  String _nextSketchName() {
    final names = (sketchApi?.sketches ?? const <Sketch>[])
        .map((item) => item.name)
        .toSet();
    var index = 1;
    while (names.contains('Sketch${index.toString().padLeft(3, '0')}')) {
      index++;
    }
    return 'Sketch${index.toString().padLeft(3, '0')}';
  }

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
  List<SketchDimension> get dimensions => constraintApi?.dimensions ?? const [];

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
    _registerOperationalCommands();
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
      activeSketch = sketch.sketches.last;
      await _synchronizeSketchScene();
    }
    if (activeSurface != null) {
      stage = SketchSurfaceStage.surfaceGenerated;
    } else if (activeSketch != null) {
      stage = SketchSurfaceStage.sketchFinished;
    } else if (activeReference != null) {
      stage = SketchSurfaceStage.referenceReady;
    }
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
      final surfaceData = region_recognition.MeshSurfaceData.fromKernel(
        geometry,
      );
      final fingerprint = document.mesh!.fingerprint;
      final segmented = await Isolate.run(
        () =>
            const ProfessionalRegionGrowing().segment(surfaceData, fingerprint),
      );
      final surfaceRegion = segmented.regions
          .where(
            (region) => region.triangleIndices.contains(pick.hit.triangleIndex),
          )
          .firstOrNull;
      if (surfaceRegion == null) {
        throw StateError(
          'Region Growing produced no homogeneous region for triangle '
          '${pick.hit.triangleIndex}.',
        );
      }
      final selection = BridgeSelection(
        id: surfaceRegion.id,
        entityId: pick.entityId,
        kind: BridgeSelectionKind.meshRegion,
        geometry: geometry,
        triangleIndices: surfaceRegion.triangleIndices.toSet(),
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
      _showRecognitionRegion(geometry, surfaceRegion);
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

  void _showRecognitionRegion(
    KernelMeshGeometry geometry,
    region_recognition.SurfaceRegion region,
  ) {
    final triangles = <int>[];
    for (final triangle in region.triangleIndices) {
      final offset = triangle * 3;
      if (offset + 2 < geometry.triangles.length) {
        triangles.addAll([
          geometry.triangles[offset],
          geometry.triangles[offset + 1],
          geometry.triangles[offset + 2],
        ]);
      }
    }
    runtime.showTransient(
      CadSceneEntity(
        id: 'recognition-region-preview',
        kind: CadSceneEntityKind.preview,
        geometry: {
          'nodes': geometry.nodes,
          'triangles': triangles,
          'color': region.color,
          'triangleCount': region.triangleIndices.length,
          'area': region.area,
        },
        transparent: true,
      ),
    );
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
  Future<void> createRecognizedReference() =>
      _run('reverse.reference.recognized');
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

  void beginSketchEditingTool(SketchToolType tool) {
    if (stage != SketchSurfaceStage.sketchActive ||
        !const {
          SketchToolType.trim,
          SketchToolType.extend,
          SketchToolType.fillet,
          SketchToolType.chamfer,
        }.contains(tool)) {
      return;
    }
    cancelSketchCommand();
    activeTool = tool;
    selectedSketchEntityIds.clear();
    runtime.select(const <String>{});
    runtime.write('sketch.edit.active', true);
    runtime.write('sketch.trim.firstId', null);
    runtime.write('sketch.trim.firstPoint', null);
    runtime.hideTransient('sketch-edit-preview');
    notifyListeners();
  }

  void setSketchEditingValue(double value) {
    if (value <= 0 || !value.isFinite) return;
    runtime.write('sketch.edit.value', value);
    _updateSketchCornerPreview();
    notifyListeners();
  }

  void setSketchFilletAutoTrim(bool value) {
    runtime.write('sketch.edit.autoTrim', value);
    notifyListeners();
  }

  Future<void> captureSketchEditingPick(CadViewportPick pick) async {
    if (!sketchEditingCommandActive) return;
    final entity = sketchApi?.entity(pick.entityId);
    if (entity == null) return;
    final local = activeSketch!.coordinates.globalToLocal(
      SketchVector(pick.hit.point.x, pick.hit.point.y, pick.hit.point.z),
    );
    if (activeTool == SketchToolType.trim) {
      if (entity is! SketchLine) {
        throw StateError('Trim currently requires line geometry.');
      }
      final start = SketchVector.fromJson(entity.parameters['start']);
      final end = SketchVector.fromJson(entity.parameters['end']);
      final dx = end.x - start.x, dy = end.y - start.y;
      final length2 = dx * dx + dy * dy;
      final t = length2 <= 1e-20
          ? .5
          : ((local.x - start.x) * dx + (local.y - start.y) * dy) / length2;
      if (t <= .18 || t >= .82) {
        await _run('reverse.sketch.edit', {
          'tool': activeTool.name,
          'trimMode': 'endpoint',
          'ids': [entity.id],
          'point': local.toJson(),
        });
        runtime.write('sketch.trim.firstId', null);
        runtime.write('sketch.trim.firstPoint', null);
        selectedSketchEntityIds.clear();
      } else {
        final firstId = runtime.read<String>('sketch.trim.firstId');
        final firstPoint = runtime.read<List<double>>('sketch.trim.firstPoint');
        if (firstId == null || firstPoint == null || firstId == entity.id) {
          runtime.write('sketch.trim.firstId', entity.id);
          runtime.write('sketch.trim.firstPoint', local.toJson());
          selectedSketchEntityIds
            ..clear()
            ..add(entity.id);
        } else {
          await _run('reverse.sketch.edit', {
            'tool': activeTool.name,
            'trimMode': 'keepSides',
            'ids': [firstId, entity.id],
            'points': [firstPoint, local.toJson()],
          });
          runtime.write('sketch.trim.firstId', null);
          runtime.write('sketch.trim.firstPoint', null);
          selectedSketchEntityIds.clear();
        }
      }
      runtime.select(selectedSketchEntityIds);
      notifyListeners();
      return;
    }
    if (!selectedSketchEntityIds.contains(entity.id)) {
      selectedSketchEntityIds.add(entity.id);
    }
    runtime.select(selectedSketchEntityIds);
    if (activeTool == SketchToolType.extend &&
        selectedSketchEntityIds.length == 2) {
      final ids = selectedSketchEntityIds.toList(growable: false);
      final intersection = _editingLineIntersection(ids[0], ids[1]);
      await _run('reverse.sketch.edit', {
        'tool': activeTool.name,
        'ids': [ids[0]],
        'point': intersection.toJson(),
      });
      selectedSketchEntityIds.clear();
    } else if (selectedSketchEntityIds.length == 2) {
      _updateSketchCornerPreview();
    }
    notifyListeners();
  }

  SketchVector _editingLineIntersection(String targetId, String referenceId) {
    final first = sketchApi?.entity(targetId);
    final second = sketchApi?.entity(referenceId);
    if (first is! SketchLine || second is! SketchLine) {
      throw StateError('Extend requires a line followed by a line reference.');
    }
    final a = SketchVector.fromJson(first.parameters['start']);
    final b = SketchVector.fromJson(first.parameters['end']);
    final c = SketchVector.fromJson(second.parameters['start']);
    final d = SketchVector.fromJson(second.parameters['end']);
    final abx = b.x - a.x, aby = b.y - a.y;
    final cdx = d.x - c.x, cdy = d.y - c.y;
    final determinant = abx * cdy - aby * cdx;
    if (determinant.abs() <= 1e-12) {
      throw StateError('Extend target and reference do not intersect.');
    }
    final t = ((c.x - a.x) * cdy - (c.y - a.y) * cdx) / determinant;
    return SketchVector(a.x + abx * t, a.y + aby * t);
  }

  void _updateSketchCornerPreview() {
    if (!const {
          SketchToolType.fillet,
          SketchToolType.chamfer,
        }.contains(activeTool) ||
        selectedSketchEntityIds.length != 2 ||
        activeSketch == null) {
      runtime.hideTransient('sketch-edit-preview');
      return;
    }
    final ids = selectedSketchEntityIds.toList(growable: false);
    final first = sketchApi?.entity(ids[0]);
    final second = sketchApi?.entity(ids[1]);
    if (first is! SketchLine || second is! SketchLine) return;
    try {
      final a = SketchVector.fromJson(first.parameters['start']);
      final b = SketchVector.fromJson(first.parameters['end']);
      final c = SketchVector.fromJson(second.parameters['start']);
      final d = SketchVector.fromJson(second.parameters['end']);
      final corner = _editingLineIntersection(ids[0], ids[1]);
      final pairs = [(a, c, b, d), (a, d, b, c), (b, c, a, d), (b, d, a, c)]
        ..sort((left, right) {
          double distance(SketchVector p, SketchVector q) =>
              math.sqrt(math.pow(p.x - q.x, 2) + math.pow(p.y - q.y, 2));
          return distance(
            left.$1,
            left.$2,
          ).compareTo(distance(right.$1, right.$2));
        });
      SketchVector direction(SketchVector far) {
        final dx = far.x - corner.x, dy = far.y - corner.y;
        final length = math.sqrt(dx * dx + dy * dy);
        return SketchVector(dx / length, dy / length);
      }

      final u1 = direction(pairs.first.$3);
      final u2 = direction(pairs.first.$4);
      final theta = math.acos((u1.x * u2.x + u1.y * u2.y).clamp(-1.0, 1.0));
      final inset = activeTool == SketchToolType.fillet
          ? sketchEditingValue / math.tan(theta / 2)
          : sketchEditingValue;
      final p1 = SketchVector(corner.x + u1.x * inset, corner.y + u1.y * inset);
      final p2 = SketchVector(corner.x + u2.x * inset, corner.y + u2.y * inset);
      final previewEntity = activeTool == SketchToolType.chamfer
          ? SketchLine(p1, p2, id: 'sketch-edit-preview-geometry')
          : () {
              final bx = u1.x + u2.x, by = u1.y + u2.y;
              final bl = math.sqrt(bx * bx + by * by);
              final distance = sketchEditingValue / math.sin(theta / 2);
              final center = SketchVector(
                corner.x + bx / bl * distance,
                corner.y + by / bl * distance,
              );
              return SketchArc(
                center,
                sketchEditingValue,
                math.atan2(p1.y - center.y, p1.x - center.x),
                math.atan2(p2.y - center.y, p2.x - center.x),
                id: 'sketch-edit-preview-geometry',
              );
            }();
      final visual = _sketchScene.adapt(
        previewEntity,
        coordinates: activeSketch!.coordinates,
      );
      runtime.showTransient(
        CadSceneEntity(
          id: 'sketch-edit-preview',
          kind: CadSceneEntityKind.preview,
          geometry: {...visual.geometry, 'color': 0xffff9800},
          transparent: true,
        ),
      );
    } catch (_) {
      runtime.hideTransient('sketch-edit-preview');
    }
  }

  Future<void> commitSketchCorner({bool? autoTrim}) async {
    if (!sketchEditingCommandActive ||
        !const {
          SketchToolType.fillet,
          SketchToolType.chamfer,
        }.contains(activeTool)) {
      return;
    }
    final ids = selectedSketchEntityIds.toList(growable: false);
    if (ids.length != 2) {
      throw StateError('Select two lines: reference first, target second.');
    }
    await _run('reverse.sketch.edit', {
      'tool': activeTool.name,
      'ids': ids,
      'value': sketchEditingValue,
      'autoTrim': autoTrim ?? sketchFilletAutoTrim,
    });
    selectedSketchEntityIds.clear();
    runtime.hideTransient('sketch-edit-preview');
    runtime.write('sketch.trim.firstId', null);
    runtime.write('sketch.trim.firstPoint', null);
    runtime.select(const <String>{});
    notifyListeners();
  }

  void finishSketchEditingTool() {
    runtime.write('sketch.edit.active', false);
    runtime.hideTransient('sketch-edit-preview');
    selectedSketchEntityIds.clear();
    runtime.select(const <String>{});
    notifyListeners();
  }

  void beginLineCommand() {
    if (stage != SketchSurfaceStage.sketchActive) return;
    if (sketchEditingCommandActive) finishSketchEditingTool();
    if (circleCommandActive) finishCircleCommand();
    if (arcCommandActive) finishArcCommand();
    activeTool = SketchToolType.line;
    selectedSketchEntityIds.clear();
    runtime.select(const <String>{});
    previewPoints = const [];
    runtime.write('sketch.line.cursor', null);
    runtime.write('sketch.line.snapType', null);
    runtime.write('sketch.line.active', true);
    final settings = editorApi?.engine.snapping.settings;
    if (settings != null) {
      settings.tolerance = .5;
      settings.gridSpacing = 1;
      settings.enabled
        ..clear()
        ..addAll(const {
          EditorSnapType.endpoint,
          EditorSnapType.midpoint,
          EditorSnapType.center,
          EditorSnapType.origin,
          EditorSnapType.grid,
        });
      settings.priority
        ..clear()
        ..addAll(const {
          EditorSnapType.endpoint: 50,
          EditorSnapType.midpoint: 40,
          EditorSnapType.center: 30,
          EditorSnapType.origin: 20,
          EditorSnapType.grid: 10,
        });
    }
    runtime.hideTransient('sketch-line-preview');
    notifyListeners();
  }

  void beginCircleCommand([
    SketchCircleMode mode = SketchCircleMode.centerRadius,
  ]) {
    if (stage != SketchSurfaceStage.sketchActive || !mode.implemented) return;
    if (sketchEditingCommandActive) finishSketchEditingTool();
    finishLineCommand();
    if (arcCommandActive) finishArcCommand();
    activeTool = SketchToolType.circle;
    selectedSketchEntityIds.clear();
    runtime.select(const <String>{});
    runtime.write('sketch.circle.mode', mode);
    runtime.write('sketch.circle.active', true);
    previewPoints = const [];
    runtime.write('sketch.circle.cursor', null);
    runtime.write('sketch.circle.snapType', null);
    _configureCreationSnaps();
    runtime.hideTransient('sketch-circle-preview');
    notifyListeners();
  }

  void beginArcCommand([SketchArcMode mode = SketchArcMode.center]) {
    if (stage != SketchSurfaceStage.sketchActive || !mode.implemented) return;
    if (sketchEditingCommandActive) finishSketchEditingTool();
    finishLineCommand();
    if (circleCommandActive) finishCircleCommand();
    activeTool = mode == SketchArcMode.threePoints
        ? SketchToolType.threePointArc
        : SketchToolType.arc;
    selectedSketchEntityIds.clear();
    runtime.select(const <String>{});
    runtime.write('sketch.arc.mode', mode);
    runtime.write('sketch.arc.active', true);
    previewPoints = const [];
    runtime.write('sketch.arc.cursor', null);
    runtime.write('sketch.arc.snapType', null);
    _configureCreationSnaps();
    runtime.hideTransient('sketch-arc-preview');
    notifyListeners();
  }

  void setCircleMode(SketchCircleMode mode) {
    if (!mode.implemented) return;
    beginCircleCommand(mode);
  }

  void _configureCreationSnaps() {
    final settings = editorApi?.engine.snapping.settings;
    if (settings == null) return;
    settings.tolerance = .5;
    settings.gridSpacing = 1;
    settings.enabled
      ..clear()
      ..addAll(const {
        EditorSnapType.endpoint,
        EditorSnapType.midpoint,
        EditorSnapType.center,
        EditorSnapType.origin,
        EditorSnapType.grid,
      });
    settings.priority
      ..clear()
      ..addAll(const {
        EditorSnapType.endpoint: 50,
        EditorSnapType.midpoint: 40,
        EditorSnapType.center: 30,
        EditorSnapType.origin: 20,
        EditorSnapType.grid: 10,
      });
  }

  void cancelSketchCommand() {
    previewPoints = const [];
    runtime.write('sketch.line.cursor', null);
    runtime.write('sketch.line.snapType', null);
    runtime.write('sketch.line.active', false);
    runtime.hideTransient('sketch-line-preview');
    runtime.write('sketch.circle.cursor', null);
    runtime.write('sketch.circle.snapType', null);
    runtime.write('sketch.circle.active', false);
    runtime.hideTransient('sketch-circle-preview');
    runtime.write('sketch.arc.cursor', null);
    runtime.write('sketch.arc.snapType', null);
    runtime.write('sketch.arc.active', false);
    runtime.hideTransient('sketch-arc-preview');
    runtime.hideTransient('sketch-endpoint-snap-marker');
    runtime.write('sketch.inference', null);
    notifyListeners();
  }

  void enterSketchSelectionMode() {
    cancelSketchCommand();
    if (sketchEditingCommandActive) finishSketchEditingTool();
    activeTool = SketchToolType.point;
    previewPoints = const [];
    runtime.hideTransient('sketch-endpoint-snap-marker');
    runtime.write('sketch.inference', null);
    runtime.select(const <String>{});
    notifyListeners();
  }

  void cancelPendingSketchOperation() {
    if (sketchEditingCommandActive) {
      finishSketchEditingTool();
      activeTool = SketchToolType.point;
      return;
    }
    if (arcCommandActive) {
      previewPoints = const [];
      runtime.write('sketch.arc.cursor', null);
      runtime.write('sketch.arc.snapType', null);
      runtime.write('sketch.arc.active', false);
      runtime.hideTransient('sketch-arc-preview');
      activeTool = SketchToolType.point;
      notifyListeners();
      return;
    }
    if (!circleCommandActive) {
      cancelSketchCommand();
      return;
    }
    previewPoints = const [];
    runtime.write('sketch.circle.cursor', null);
    runtime.hideTransient('sketch-circle-preview');
    notifyListeners();
  }

  void finishLineCommand() {
    if (!lineCommandActive) return;
    previewPoints = const [];
    runtime.write('sketch.line.cursor', null);
    runtime.write('sketch.line.snapType', null);
    runtime.write('sketch.line.active', false);
    runtime.hideTransient('sketch-line-preview');
    runtime.hideTransient('sketch-endpoint-snap-marker');
    runtime.write('sketch.inference', null);
    notifyListeners();
  }

  void finishCircleCommand() {
    if (!circleCommandActive) return;
    previewPoints = const [];
    runtime.write('sketch.circle.cursor', null);
    runtime.write('sketch.circle.snapType', null);
    runtime.write('sketch.circle.active', false);
    runtime.hideTransient('sketch-circle-preview');
    runtime.hideTransient('sketch-endpoint-snap-marker');
    runtime.write('sketch.inference', null);
    activeTool = SketchToolType.point;
    notifyListeners();
  }

  void finishArcCommand() {
    if (!arcCommandActive) return;
    previewPoints = const [];
    runtime.write('sketch.arc.cursor', null);
    runtime.write('sketch.arc.snapType', null);
    runtime.write('sketch.arc.active', false);
    runtime.hideTransient('sketch-arc-preview');
    runtime.hideTransient('sketch-endpoint-snap-marker');
    activeTool = SketchToolType.point;
    notifyListeners();
  }

  SketchVector? _sketchPointAt(Offset position, CadCameraController camera) {
    final geometry = activeSketchPlane;
    if (geometry is! PlaneGeometry || activeSketch == null) return null;
    Vector3 vector(List<double> value) => Vector3(value[0], value[1], value[2]);
    final world = _viewportPicking.pointOnPlane(
      position: position,
      camera: camera,
      origin: vector(geometry.origin.toJson()),
      normal: vector(geometry.normal.toJson()).normalized,
    );
    if (world == null) return null;
    final local = activeSketch!.coordinates.globalToLocal(
      SketchVector(world.x, world.y, world.z),
    );
    final raw = SketchVector(local.x, local.y);
    final snap = editorApi?.snap(raw);
    final inference = _sketchInference.inferLine(
      cursor: raw,
      start: lineCommandActive ? previewPoints.firstOrNull : null,
      entities: sketchEntities,
      snap: snap,
      spatialTolerance: editorApi?.engine.snapping.settings.tolerance ?? .5,
    );
    runtime.write('sketch.inference', inference);
    if (arcCommandActive) {
      runtime.write('sketch.arc.snapType', snap?.type);
    } else if (circleCommandActive) {
      runtime.write('sketch.circle.snapType', snap?.type);
    } else {
      runtime.write('sketch.line.snapType', snap?.type);
    }
    return inference?.position ?? snap?.position ?? raw;
  }

  void previewSketchPointer(Offset position, CadCameraController camera) {
    if (!sketchCreationCommandActive) return;
    runtime.write('sketch.inference.cursor', position);
    final point = _sketchPointAt(position, camera);
    if (point == null) return;
    if (previewPoints.isEmpty) {
      notifyListeners();
      return;
    }
    if (arcCommandActive) {
      runtime.write('sketch.arc.cursor', point);
      final definition = professionalArcDefinition(arcMode, [
        ...previewPoints,
        point,
      ]);
      if (definition == null) {
        runtime.hideTransient('sketch-arc-preview');
        notifyListeners();
        return;
      }
      final coordinates = activeSketch!.coordinates;
      runtime.showTransient(
        CadSceneEntity(
          id: 'sketch-arc-preview',
          kind: CadSceneEntityKind.preview,
          transparent: true,
          geometry: {
            'points': [
              for (var index = 0; index <= 48; index++)
                coordinates
                    .localToGlobal(
                      SketchVector(
                        definition.center.x +
                            definition.radius *
                                math.cos(
                                  definition.startAngle +
                                      (definition.endAngle -
                                              definition.startAngle) *
                                          index /
                                          48,
                                ),
                        definition.center.y +
                            definition.radius *
                                math.sin(
                                  definition.startAngle +
                                      (definition.endAngle -
                                              definition.startAngle) *
                                          index /
                                          48,
                                ),
                      ),
                    )
                    .toJson(),
            ],
            'displayColor': 'previewOrange',
            'strokeWidth': SketchSceneAdapter.technicalStrokeWidth,
          },
        ),
      );
      notifyListeners();
      return;
    }
    if (circleCommandActive) {
      runtime.write('sketch.circle.cursor', point);
      final definition = professionalCircleDefinition(circleMode, [
        ...previewPoints,
        point,
      ]);
      if (definition == null) {
        runtime.hideTransient('sketch-circle-preview');
        notifyListeners();
        return;
      }
      final coordinates = activeSketch!.coordinates;
      runtime.showTransient(
        CadSceneEntity(
          id: 'sketch-circle-preview',
          kind: CadSceneEntityKind.preview,
          transparent: true,
          geometry: {
            'points': [
              for (var index = 0; index <= 72; index++)
                coordinates
                    .localToGlobal(
                      SketchVector(
                        definition.center.x +
                            definition.radius *
                                math.cos(index * math.pi * 2 / 72),
                        definition.center.y +
                            definition.radius *
                                math.sin(index * math.pi * 2 / 72),
                      ),
                    )
                    .toJson(),
            ],
            'displayColor': 'previewOrange',
            'strokeWidth': SketchSceneAdapter.technicalStrokeWidth,
          },
        ),
      );
      notifyListeners();
      return;
    }
    runtime.write('sketch.line.cursor', point);
    final coordinates = activeSketch!.coordinates;
    runtime.showTransient(
      CadSceneEntity(
        id: 'sketch-line-preview',
        kind: CadSceneEntityKind.preview,
        transparent: true,
        geometry: {
          'points': [
            coordinates.localToGlobal(previewPoints.first).toJson(),
            coordinates.localToGlobal(point).toJson(),
          ],
          'displayColor': 'previewOrange',
          'strokeWidth': SketchSceneAdapter.technicalStrokeWidth,
        },
      ),
    );
    notifyListeners();
  }

  Future<void> captureSketchTap(
    Offset position,
    CadCameraController camera,
  ) async {
    runtime.hideTransient('sketch-endpoint-snap-marker');
    runtime.write('sketch.inference', null);
    if (!sketchCreationCommandActive ||
        stage != SketchSurfaceStage.sketchActive) {
      return;
    }
    final point = _sketchPointAt(position, camera);
    if (point == null) return;
    if (arcCommandActive) {
      final captured = [...previewPoints, point];
      if (captured.length < arcMode.requiredPoints) {
        previewPoints = captured;
        runtime.write('sketch.arc.cursor', point);
        runtime.write('sketch.inference', null);
        notifyListeners();
        return;
      }
      final definition = professionalArcDefinition(arcMode, captured);
      if (definition != null && definition.radius > 1e-9) {
        await _run('reverse.sketch.draw', {
          'tool': SketchToolType.arc.name,
          'points': [
            definition.center.toJson(),
            SketchVector(
              definition.center.x + definition.radius,
              definition.center.y,
            ).toJson(),
          ],
          'operationParameters': {
            'startAngle': definition.startAngle,
            'endAngle': definition.endAngle,
          },
        });
      }
      previewPoints = const [];
      runtime.write('sketch.arc.cursor', null);
      runtime.hideTransient('sketch-arc-preview');
      runtime.write('sketch.inference', null);
      notifyListeners();
      return;
    }
    if (circleCommandActive) {
      final captured = [...previewPoints, point];
      if (captured.length < circleMode.requiredPoints) {
        previewPoints = captured;
        runtime.write('sketch.circle.cursor', point);
        runtime.write('sketch.inference', null);
        notifyListeners();
        return;
      }
      final definition = professionalCircleDefinition(circleMode, captured);
      if (definition != null && definition.radius > 1e-9) {
        await _run('reverse.sketch.draw', {
          'tool': SketchToolType.circle.name,
          'points': [
            definition.center.toJson(),
            SketchVector(
              definition.center.x + definition.radius,
              definition.center.y,
            ).toJson(),
          ],
        });
      }
      previewPoints = const [];
      runtime.write('sketch.circle.cursor', null);
      runtime.hideTransient('sketch-circle-preview');
      runtime.write('sketch.inference', null);
      notifyListeners();
      return;
    }
    if (previewPoints.isEmpty) {
      previewPoints = [point];
      runtime.write('sketch.line.cursor', point);
      runtime.write('sketch.inference', null);
      notifyListeners();
      return;
    }
    final start = previewPoints.first;
    final dx = point.x - start.x;
    final dy = point.y - start.y;
    if (dx * dx + dy * dy > 1e-18) {
      await _run('reverse.sketch.draw', {
        'tool': SketchToolType.line.name,
        'points': [start.toJson(), point.toJson()],
      });
      // The Line command remains active, but every committed entity starts a
      // fresh two-click capture. No tool reactivation is required.
      previewPoints = const [];
      runtime.write('sketch.line.cursor', null);
      runtime.hideTransient('sketch-line-preview');
      runtime.write('sketch.inference', null);
      notifyListeners();
    }
  }

  /// Commits the current professional creation command from typed values.
  /// The first geometric click remains the anchor; completion stays
  /// persistent exactly like the mouse workflow.
  Future<bool> commitDirectSketchValues({
    required double primary,
    double? secondary,
    double? tertiary,
    bool diameter = false,
  }) async {
    if (!primary.isFinite || primary <= 0 || previewPoints.isEmpty) {
      return false;
    }
    if (lineCommandActive) {
      final angleDegrees = secondary ?? 0;
      if (!angleDegrees.isFinite) return false;
      final start = previewPoints.first;
      final angle = angleDegrees * math.pi / 180;
      final end = SketchVector(
        start.x + primary * math.cos(angle),
        start.y + primary * math.sin(angle),
      );
      await _run('reverse.sketch.draw', {
        'tool': SketchToolType.line.name,
        'points': [start.toJson(), end.toJson()],
      });
      previewPoints = const [];
      runtime.write('sketch.line.cursor', null);
      runtime.hideTransient('sketch-line-preview');
    } else if (circleCommandActive) {
      final center = previewPoints.first;
      final radius = diameter ? primary / 2 : primary;
      await _run('reverse.sketch.draw', {
        'tool': SketchToolType.circle.name,
        'points': [
          center.toJson(),
          SketchVector(center.x + radius, center.y).toJson(),
        ],
      });
      previewPoints = const [];
      runtime.write('sketch.circle.cursor', null);
      runtime.hideTransient('sketch-circle-preview');
    } else if (arcCommandActive) {
      final center = previewPoints.first;
      final start = (secondary ?? 0) * math.pi / 180;
      final end = (tertiary ?? 90) * math.pi / 180;
      if (!start.isFinite || !end.isFinite) return false;
      await _run('reverse.sketch.draw', {
        'tool': SketchToolType.arc.name,
        'points': [
          center.toJson(),
          SketchVector(center.x + primary, center.y).toJson(),
        ],
        'operationParameters': {'startAngle': start, 'endAngle': end},
      });
      previewPoints = const [];
      runtime.write('sketch.arc.cursor', null);
      runtime.hideTransient('sketch-arc-preview');
    } else {
      return false;
    }
    notifyListeners();
    return true;
  }

  static ({SketchVector center, double radius})? professionalCircleDefinition(
    SketchCircleMode mode,
    List<SketchVector> points,
  ) {
    if (points.length < 2) return null;
    switch (mode) {
      case SketchCircleMode.centerRadius:
        return (
          center: points[0],
          radius: _circleDistance(points[0], points[1]),
        );
      case SketchCircleMode.centerDiameter:
        return (
          center: points[0],
          radius: _circleDistance(points[0], points[1]) / 2,
        );
      case SketchCircleMode.twoPoints:
        return (
          center: SketchVector(
            (points[0].x + points[1].x) / 2,
            (points[0].y + points[1].y) / 2,
          ),
          radius: _circleDistance(points[0], points[1]) / 2,
        );
      case SketchCircleMode.threePoints:
        if (points.length < 3) return null;
        final a = points[0], b = points[1], c = points[2];
        final denominator =
            2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
        if (denominator.abs() <= 1e-12) return null;
        final aa = a.x * a.x + a.y * a.y;
        final bb = b.x * b.x + b.y * b.y;
        final cc = c.x * c.x + c.y * c.y;
        final center = SketchVector(
          (aa * (b.y - c.y) + bb * (c.y - a.y) + cc * (a.y - b.y)) /
              denominator,
          (aa * (c.x - b.x) + bb * (a.x - c.x) + cc * (b.x - a.x)) /
              denominator,
        );
        return (center: center, radius: _circleDistance(center, a));
      case SketchCircleMode.tangentRadius:
      case SketchCircleMode.tangentTangentRadius:
      case SketchCircleMode.threeTangencies:
        return null;
    }
  }

  static double _circleDistance(SketchVector first, SketchVector second) {
    final dx = second.x - first.x;
    final dy = second.y - first.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static ({
    SketchVector center,
    double radius,
    double startAngle,
    double endAngle,
  })?
  professionalArcDefinition(SketchArcMode mode, List<SketchVector> points) {
    if (points.length < 3 || !mode.implemented) return null;
    if (mode == SketchArcMode.center) {
      final center = points[0];
      final radius = _circleDistance(center, points[1]);
      if (radius <= 1e-12) return null;
      final start = math.atan2(points[1].y - center.y, points[1].x - center.x);
      var end = math.atan2(points[2].y - center.y, points[2].x - center.x);
      while (end <= start) {
        end += math.pi * 2;
      }
      return (center: center, radius: radius, startAngle: start, endAngle: end);
    }
    if (mode == SketchArcMode.threePoints) {
      final circle = professionalCircleDefinition(
        SketchCircleMode.threePoints,
        points,
      );
      if (circle == null) return null;
      final start = math.atan2(
        points[0].y - circle.center.y,
        points[0].x - circle.center.x,
      );
      final middle = math.atan2(
        points[1].y - circle.center.y,
        points[1].x - circle.center.x,
      );
      final rawEnd = math.atan2(
        points[2].y - circle.center.y,
        points[2].x - circle.center.x,
      );
      final fullTurn = math.pi * 2;
      double positiveDelta(double angle) =>
          ((angle - start) % fullTurn + fullTurn) % fullTurn;
      final middleCcw = positiveDelta(middle);
      final endCcw = positiveDelta(rawEnd);
      final end = middleCcw <= endCcw
          ? start + endCcw
          : start - (fullTurn - endCcw);
      return (
        center: circle.center,
        radius: circle.radius,
        startAngle: start,
        endAngle: end,
      );
    }
    return null;
  }

  Future<void> deleteSelectedSketchEntities() async {
    final ids = selectedSketchEntityIds.toList();
    if (ids.isEmpty) return;
    await _run('reverse.sketch.delete', {'ids': ids});
    selectedSketchEntityIds.clear();
    notifyListeners();
  }

  /// G-124 dynamic edit: changes the existing entity in place, preserving its
  /// identity, Explorer node and command history.
  Future<void> updateSketchEntityParameters(
    String id,
    Map<String, double> values,
  ) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await commands.dispatch('reverse.sketch.parameters', {
        'id': id,
        'values': values,
      });
      runtime.select({id});
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> setSketchEntityVisibility(String id, bool visible) async {
    final api = sketchApi ?? (throw StateError('Sketch is not available.'));
    if (api.entity(id) == null) {
      throw StateError('Unknown Sketch entity: $id');
    }
    api.engine.modify(
      id,
      SketchHistoryAction.modify,
      (value) => value.visible = visible,
    );
    final visual = runtime.scene.find(id);
    if (visual != null) runtime.scene.upsert(visual.copyWith(visible: visible));
    await api.persist();
    await runtime.setEntityVisibility(id, visible);
    notifyListeners();
  }

  void highlightSketchHealthIssue(SketchHealthIssue issue) {
    selectedConstraintIds.clear();
    selectedSketchEntityIds
      ..clear()
      ..addAll(issue.entityIds);
    runtime.select(issue.entityIds.toSet());
    if (activeSketch case final sketch?) {
      runtime.showTransient(
        CadSceneEntity(
          id: 'sketch-health-highlight',
          kind: CadSceneEntityKind.preview,
          transparent: true,
          geometry: {
            'points': issue.locations
                .map(sketch.coordinates.localToGlobal)
                .map((point) => point.toJson())
                .toList(growable: false),
            'displayColor': 'conflictRed',
            'strokeWidth': 2.0,
            'healthIssue': issue.type.name,
          },
        ),
      );
    }
    notifyListeners();
  }

  Future<void> autoHealSketchGap(SketchHealthIssue issue) async {
    if (issue.type != SketchHealthIssueType.gap ||
        !issue.canAutoHeal ||
        issue.endpointReferences.length != 2) {
      throw StateError('This Sketch issue has no safe automatic repair.');
    }
    final affected = constraints.where(
      (constraint) => constraint.references.any((reference) {
        final constrainedId = reference.replaceFirst(
          RegExp(r':(start|end|point)$'),
          '',
        );
        return issue.endpointReferences.any(
          (endpoint) =>
              endpoint.replaceFirst(RegExp(r':(start|end)$'), '') ==
              constrainedId,
        );
      }),
    );
    if (affected.isNotEmpty) {
      throw StateError(
        'Gap repair is blocked by ${affected.first.type.name} '
        '(${affected.first.id}).',
      );
    }
    final midpoint = SketchVector(
      (issue.locations[0].x + issue.locations[1].x) / 2,
      (issue.locations[0].y + issue.locations[1].y) / 2,
      (issue.locations[0].z + issue.locations[1].z) / 2,
    );
    sketchApi!.engine.transaction('sketch-health:auto-heal-gap', () {
      for (final reference in issue.endpointReferences) {
        final entityId = reference.replaceFirst(RegExp(r':(start|end)$'), '');
        sketchApi!.engine.modify(entityId, SketchHistoryAction.modify, (
          entity,
        ) {
          if (entity is SketchLine) {
            entity.parameters[reference.endsWith(':start') ? 'start' : 'end'] =
                midpoint.toJson();
            entity.refreshDerivedParameters();
          } else if (entity is SketchArc) {
            final center = SketchVector.fromJson(entity.parameters['center']);
            entity.parameters[reference.endsWith(':start')
                ? 'startAngle'
                : 'endAngle'] = math.atan2(
              midpoint.y - center.y,
              midpoint.x - center.x,
            );
          }
        });
      }
    });
    runtime.hideTransient('sketch-health-highlight');
    await _synchronizeSketchScene();
    notifyListeners();
  }

  Future<void> updateSketchFeatureParameter(String id, double value) =>
      _run('reverse.sketch.feature.parameters', {'id': id, 'value': value});

  void reopenSketchFeature(String id) {
    final entity =
        sketchApi?.entity(id) ??
        (throw StateError('Unknown Sketch feature: $id'));
    final type = entity.metadata['featureType'] as String?;
    activeTool = type == 'fillet'
        ? SketchToolType.fillet
        : type == 'chamfer'
        ? SketchToolType.chamfer
        : throw StateError('$id is not an editable Sketch feature.');
    runtime.write('sketch.edit.active', true);
    runtime.write(
      'sketch.edit.value',
      (entity.metadata['featureValue'] as num?)?.toDouble() ?? 1,
    );
    selectedSketchEntityIds
      ..clear()
      ..add(id);
    runtime.select({id});
    notifyListeners();
  }

  Future<void> constrainRectangle() =>
      _run('reverse.sketch.constrainRectangle');
  Future<void> createDrivingDimension(
    SketchDimensionType type,
    double value, {
    String? anchorReference,
  }) async {
    if (selectedSketchEntityIds.length != 1) {
      throw StateError('Select exactly one Sketch entity for this dimension.');
    }
    final entity = sketchApi?.entity(selectedSketchEntityIds.single);
    var label = const SketchVector(0, 0);
    if (entity is SketchLine) {
      final a = SketchVector.fromJson(entity.parameters['start']);
      final b = SketchVector.fromJson(entity.parameters['end']);
      label = SketchVector(
        (a.x + b.x) / 2 - (b.y - a.y) * .15,
        (a.y + b.y) / 2 + (b.x - a.x) * .15,
      );
    } else if (entity is SketchCircle || entity is SketchArc) {
      final center = SketchVector.fromJson(entity!.parameters['center']);
      final radius = (entity.parameters['radius'] as num).toDouble();
      label = SketchVector(center.x + radius * .8, center.y + radius * .8);
    }
    await _run('reverse.sketch.dimension.create', {
      'type': type.name,
      'value': value,
      'references': [selectedSketchEntityIds.single],
      'anchorReference': anchorReference,
      'labelX': label.x,
      'labelY': label.y,
    });
  }

  Future<void> editDrivingDimension(String id, double value) =>
      _run('reverse.sketch.dimension.edit', {'id': id, 'value': value});

  Future<void> deleteDrivingDimension(String id) =>
      _run('reverse.sketch.dimension.delete', {'id': id});

  Future<void> moveDimensionLabel(String id, SketchVector position) => _run(
    'reverse.sketch.dimension.move',
    {'id': id, 'x': position.x, 'y': position.y},
  );
  Future<void> applyConstraint(SketchConstraintType type, {double? value}) {
    final references = _constraintReferences(type);
    return _run('reverse.sketch.constraint', {
      'type': type.name,
      'value': ?value,
      'references': references,
    });
  }

  /// Builds directional references for scan-derived geometry. Selection order
  /// is intentional: the first entity is the trusted reference and the second
  /// is the entity the solver is allowed to correct.
  List<String> _constraintReferences(SketchConstraintType type) {
    final selected = selectedSketchEntityIds
        .map((id) => sketchApi?.entity(id))
        .whereType<SketchEntity>()
        .toList(growable: false);
    StateError invalid(String requirement) => StateError(
      '${_constraintLabel(type)} requires $requirement. '
      'Select the reference first and the geometry to correct second.',
    );
    switch (type) {
      case SketchConstraintType.horizontal:
      case SketchConstraintType.vertical:
        if (selected.length != 1 || selected.single is! SketchLine) {
          throw invalid('one line');
        }
        return [selected.single.id];
      case SketchConstraintType.parallel:
      case SketchConstraintType.perpendicular:
        if (selected.length != 2 || selected.any((e) => e is! SketchLine)) {
          throw invalid('two lines');
        }
        return selected.map((e) => e.id).toList(growable: false);
      case SketchConstraintType.concentric:
        if (selected.length != 2 ||
            selected.any((e) => e is! SketchCircle && e is! SketchArc)) {
          throw invalid('two circles or arcs');
        }
        return selected.map((e) => e.id).toList(growable: false);
      case SketchConstraintType.coincident:
        if (selected.length != 2 ||
            selected.any((e) => e is! SketchLine && e is! SketchPoint)) {
          throw invalid('two lines or points');
        }
        return _nearestEndpointReferences(selected[0], selected[1]);
      default:
        throw StateError(
          '${_constraintLabel(type)} is not available in G-125.',
        );
    }
  }

  List<String> _nearestEndpointReferences(
    SketchEntity first,
    SketchEntity second,
  ) {
    List<(String, SketchVector)> candidates(SketchEntity entity) {
      if (entity is SketchPoint) {
        return [(entity.id, SketchVector.fromJson(entity.parameters['point']))];
      }
      final line = entity as SketchLine;
      return [
        ('${line.id}:start', SketchVector.fromJson(line.parameters['start'])),
        ('${line.id}:end', SketchVector.fromJson(line.parameters['end'])),
      ];
    }

    final a = candidates(first);
    final b = candidates(second);
    var bestA = a.first;
    var bestB = b.first;
    var bestDistance = double.infinity;
    for (final pa in a) {
      for (final pb in b) {
        final delta = pa.$2 - pb.$2;
        final distance = math.sqrt(
          delta.x * delta.x + delta.y * delta.y + delta.z * delta.z,
        );
        if (distance < bestDistance) {
          bestDistance = distance;
          bestA = pa;
          bestB = pb;
        }
      }
    }
    return [bestA.$1, bestB.$1];
  }

  static String _constraintLabel(SketchConstraintType type) => switch (type) {
    SketchConstraintType.horizontal => 'Horizontal',
    SketchConstraintType.vertical => 'Vertical',
    SketchConstraintType.coincident => 'Coincident',
    SketchConstraintType.parallel => 'Parallel',
    SketchConstraintType.perpendicular => 'Perpendicular',
    SketchConstraintType.concentric => 'Concentric',
    _ => type.name,
  };

  void _validateConstrainedParameterEdit(
    SketchEntity entity,
    Map<String, double> values,
  ) {
    final requestedAngle = values['angleDegrees'];
    if (requestedAngle == null || entity is! SketchLine) return;
    double normalized(double value) {
      final result = value % 180;
      return result < 0 ? result + 180 : result;
    }

    bool sameAngle(double a, double b) =>
        (normalized(a) - normalized(b)).abs() < 1e-7;
    for (final constraint in constraints.where(
      (item) =>
          item.enabled &&
          !item.suppressed &&
          item.references.any(
            (reference) => reference.split(':').first == entity.id,
          ),
    )) {
      double? required;
      switch (constraint.type) {
        case SketchConstraintType.horizontal:
          required = 0;
          break;
        case SketchConstraintType.vertical:
          required = 90;
          break;
        case SketchConstraintType.parallel:
        case SketchConstraintType.perpendicular:
          final otherId = constraint.references
              .map((reference) => reference.split(':').first)
              .firstWhere((id) => id != entity.id, orElse: () => '');
          final other = sketchApi?.entity(otherId);
          if (other is SketchLine) {
            required =
                (other.parameters['angleDegrees'] as num).toDouble() +
                (constraint.type == SketchConstraintType.perpendicular
                    ? 90
                    : 0);
          }
          break;
        default:
          continue;
      }
      if (required != null && !sameAngle(requestedAngle, required)) {
        throw StateError(
          '${_constraintLabel(constraint.type)} (${constraint.id}) prevents '
          'Angle = ${requestedAngle.toStringAsFixed(3)}°. '
          'Delete or suppress that constraint before changing this angle.',
        );
      }
    }
  }

  List<(String, String)> _currentSketchConnections() {
    final endpoints = <(String, SketchVector)>[];
    for (final entity in sketchEntities) {
      if (entity is SketchLine) {
        endpoints.addAll([
          (
            '${entity.id}:start',
            SketchVector.fromJson(entity.parameters['start']),
          ),
          ('${entity.id}:end', SketchVector.fromJson(entity.parameters['end'])),
        ]);
      } else if (entity is SketchArc) {
        final center = SketchVector.fromJson(entity.parameters['center']);
        final radius = (entity.parameters['radius'] as num).toDouble();
        for (final entry in <(String, double)>[
          ('start', (entity.parameters['startAngle'] as num).toDouble()),
          ('end', (entity.parameters['endAngle'] as num).toDouble()),
        ]) {
          endpoints.add((
            '${entity.id}:${entry.$1}',
            SketchVector(
              center.x + radius * math.cos(entry.$2),
              center.y + radius * math.sin(entry.$2),
            ),
          ));
        }
      }
    }
    final result = <(String, String)>[];
    for (var i = 0; i < endpoints.length; i++) {
      for (var j = i + 1; j < endpoints.length; j++) {
        if (endpoints[i].$1.split(':').first ==
            endpoints[j].$1.split(':').first) {
          continue;
        }
        final delta = endpoints[i].$2 - endpoints[j].$2;
        if (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z <= 1e-8) {
          result.add((endpoints[i].$1, endpoints[j].$1));
        }
      }
    }
    return result;
  }

  SketchVector? _sketchEndpoint(String reference) {
    final parts = reference.split(':');
    final entity = sketchApi?.entity(parts.first);
    final end = parts.last;
    if (entity is SketchLine) {
      return SketchVector.fromJson(entity.parameters[end]);
    }
    if (entity is SketchArc) {
      final center = SketchVector.fromJson(entity.parameters['center']);
      final radius = (entity.parameters['radius'] as num).toDouble();
      final angle = (entity.parameters['${end}Angle'] as num).toDouble();
      return SketchVector(
        center.x + radius * math.cos(angle),
        center.y + radius * math.sin(angle),
      );
    }
    return null;
  }

  void _assertSketchConnectionsPreserved(List<(String, String)> before) {
    for (final pair in before) {
      final a = _sketchEndpoint(pair.$1), b = _sketchEndpoint(pair.$2);
      if (a == null || b == null) continue;
      final delta = a - b;
      if (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z > 1e-8) {
        final blocker = constraints.where((constraint) {
          final refs = constraint.references.toSet();
          return refs.contains(pair.$1) && refs.contains(pair.$2);
        }).firstOrNull;
        throw StateError(
          'Sketch over constrained: this edit would disconnect ${pair.$1} from ${pair.$2}'
          '${blocker == null ? '' : ' because of ${_constraintLabel(blocker.type)} (${blocker.id})'}.',
        );
      }
    }
  }

  void toggleSketchSelection(String id) {
    if (!selectedSketchEntityIds.add(id)) {
      selectedSketchEntityIds.remove(id);
    }
    runtime.select(_selectionWithDimensions());
    notifyListeners();
  }

  void selectSketchEntity(String id, {bool additive = false}) {
    if (sketchApi?.entity(id) == null) return;
    selectedConstraintIds.clear();
    if (!additive) selectedSketchEntityIds.clear();
    selectedSketchEntityIds.add(id);
    runtime.select(_selectionWithDimensions());
    notifyListeners();
  }

  Set<String> _selectionWithDimensions() => {
    ...selectedSketchEntityIds,
    for (final dimension in dimensions)
      if (dimension.references.any(selectedSketchEntityIds.contains))
        dimension.id,
  };

  void selectConstraint(String id, {bool additive = false}) {
    if (!constraints.any((item) => item.id == id)) return;
    if (!additive) selectedConstraintIds.clear();
    selectedConstraintIds.add(id);
    selectedSketchEntityIds.clear();
    runtime.select({id});
    notifyListeners();
  }

  Future<void> deleteConstraint(String id) async {
    await _run('reverse.sketch.constraint.delete', {'id': id});
    selectedConstraintIds.remove(id);
    notifyListeners();
  }

  Future<void> setConstraintVisibility(String id, bool visible) async {
    constraintApi?.setVisible(id, visible);
    await _synchronizeSketchScene();
    notifyListeners();
  }

  Future<void> finishSketch() => _run('reverse.sketch.finish');
  Future<void> previewPlanarSurface() {
    if (!sketchReadyForSurface) throw StateError(sketchSurfaceBlockReason);
    return _run('reverse.surface.preview');
  }

  Future<void> confirmSurface() => _run('reverse.surface.confirm');
  bool canCreateRecognizedSurface(SurfaceKind kind) {
    final primitive = (report?.primitives ?? const <ProfessionalPrimitive>[])
        .where((item) => item.recognition.winner.type.name == kind.name)
        .firstOrNull;
    return primitive != null &&
        decisions[primitive.recognition.id] == RecognitionDecision.accepted &&
        {
          SurfaceKind.cylinder,
          SurfaceKind.cone,
          SurfaceKind.sphere,
          SurfaceKind.torus,
        }.contains(kind);
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
        SurfaceKind.cone => await api.cone.fromCandidate(
          candidate,
          apex: (parameters['origin'] as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList(),
          axisDirection: (parameters['axis'] as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList(),
          semiAngle: (parameters['halfAngle'] as num).toDouble(),
        ),
        SurfaceKind.torus => await api.torus.fromCandidate(
          candidate,
          center: (parameters['center'] as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList(),
          axisDirection: (parameters['axis'] as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList(),
          majorRadius: (parameters['majorRadius'] as num).toDouble(),
          minorRadius: (parameters['minorRadius'] as num).toDouble(),
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
    final count = _selectedProfessionalInputCount;
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
    if (api == null || !canPreviewProfessional(tool)) {
      throw StateError('Select valid kernel shapes for ${tool.name}.');
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final handles = await _selectedProfessionalInputHandles(tool);
      final sourceEntityIds = <String>{
        ...runtime.selection,
        ..._selectedSketches.map((sketch) => sketch.id),
      }.toList(growable: false);
      final draft = api.begin(
        tool: tool,
        references: handles.map((item) => item.persistentId).toList(),
        parameters: {
          'shapeHandles': handles.map((item) => item.toJson()).toList(),
          'sourceEntityIds': sourceEntityIds,
          if (tool == ProfessionalSurfaceTool.blend) ...{
            'radius': 1.0,
            'continuity': 1,
            'tolerance': 1e-4,
            'angularTolerance': 1e-3,
          },
        },
        continuity: tool == ProfessionalSurfaceTool.blend
            ? SurfaceContinuity.g1
            : SurfaceContinuity.g0,
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
        await _reportProfessionalSurfaceResult(
          tool: tool,
          handle: handle,
          affectedEntities: handles.length,
          parameters: draft.definition.parameters,
          state: 'Preview',
        );
      }
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _reportProfessionalSurfaceResult({
    required ProfessionalSurfaceTool tool,
    required ShapeHandle handle,
    required int affectedEntities,
    required Map<String, dynamic> parameters,
    required String state,
  }) async {
    final api = professionalSurfaceApi;
    if (api == null) return;
    final diagnostics = await api.kernel.validate(handle, const {
      'brep',
      'topology',
      'tolerance',
      'manifold',
    });
    var boundaries = 0, loops = 0;
    if (api.kernel is SurfaceTopologyKernelAPI) {
      try {
        final topology = await (api.kernel as SurfaceTopologyKernelAPI)
            .inspectSurfaceTopology(handle);
        boundaries = topology.boundaries.length;
        loops = topology.loops.length;
      } on Object {
        // A Shell/Solid result is validated by BRepCheck; face-only topology
        // metrics are intentionally unavailable for that result type.
      }
    }
    final critical = diagnostics.any((item) => item.startsWith('error:'));
    final attention = diagnostics.any((item) => item.startsWith('warning:'));
    runtime.write('surface.operationReport', <String, dynamic>{
      'operation': tool.name,
      'state': state,
      'affectedEntities': affectedEntities,
      'boundaries': boundaries,
      'loops': loops,
      'tolerance':
          parameters['tolerance'] ??
          parameters['tolerance3d'] ??
          parameters['distance'] ??
          '-',
      'diagnostics': diagnostics,
      if (tool == ProfessionalSurfaceTool.match) ...{
        'continuityRequested': parameters['continuity'] ?? 'G1',
        'distanceTolerance': parameters['tolerance3d'] ?? 1e-4,
        'angularTolerance': parameters['angularTolerance'] ?? 1e-2,
        'curvatureTolerance': parameters['curvatureTolerance'] ?? 1e-1,
        'constraintSamples': parameters['pointsOnCurve'] ?? 10,
      },
      if (tool == ProfessionalSurfaceTool.blend) ...{
        'route': affectedEntities > 2 ? 'general-boundary' : 'shared-edge',
        'radius': parameters['radius'] ?? 1.0,
        'continuityRequested': parameters['continuity'] ?? 'G1',
        'angularTolerance': parameters['angularTolerance'] ?? 1e-3,
      },
      if (tool == ProfessionalSurfaceTool.offsetWalls) ...{
        'signedDistance': parameters['distance'] ?? 0,
        'offsetMode': parameters['offsetMode'] ?? 'walls',
        'direction': parameters['direction'] ?? 'outside',
        'wallBoundaryIds': parameters['wallBoundaryIds'] ?? const [],
        'openBoundaryIds': parameters['openBoundaryIds'] ?? const [],
        'join': parameters['join'] ?? 'arc',
        'closeResult': parameters['closeResult'] ?? true,
        'topologicalResult': handle.type.name,
      },
      if (tool == ProfessionalSurfaceTool.boundaryExtend) ...{
        'mode': parameters['mode'] ?? 'byLength',
        'requestedLength': parameters['length'] ?? 0,
        'continuityRequested': parameters['continuity'] ?? 1,
        'parametricDirection': parameters['inU'] == true ? 'U' : 'V',
        'side': parameters['after'] == false ? 'before' : 'after',
      },
      if (tool == ProfessionalSurfaceTool.boundaryTrim) ...{
        'keepPoint': parameters['hasKeepPoint'] == true
            ? [
                parameters['keepPointX'],
                parameters['keepPointY'],
                parameters['keepPointZ'],
              ]
            : null,
        'cuttingTools': affectedEntities - 1,
      },
      if ({
        ProfessionalSurfaceTool.unsewFace,
        ProfessionalSurfaceTool.unsewSelected,
        ProfessionalSurfaceTool.unsewAll,
      }.contains(tool)) ...{
        'topologyAction': tool.name,
        'newOpenBoundariesRequireValidation': true,
      },
      if (tool == ProfessionalSurfaceTool.replaceFace) ...{
        'topologyAction': 'replaceFace',
        'boundaryCorrespondenceValidated': !critical,
      },
      if (tool == ProfessionalSurfaceTool.deleteFace) ...{
        'topologyAction': 'deleteFace',
        'resultingShellMayBeOpen': true,
      },
      if (tool == ProfessionalSurfaceTool.healLocal) ...{
        'healScope': 'local',
        'globalChangesAllowed': false,
      },
      'result': critical
          ? 'Critical'
          : attention
          ? 'Attention'
          : 'OK',
    });
  }

  int get _selectedProfessionalInputCount {
    final ids = <String>{};
    final document = runtime.document;
    for (final id in runtime.selection) {
      final entity = document?.entities[id];
      if (entity?.shape != null || _isConvertibleSurfaceInput(entity)) {
        ids.add(id);
      }
    }
    for (final sketch in _selectedSketches) {
      ids.add(sketch.id);
    }
    return ids.length;
  }

  bool _isConvertibleSurfaceInput(CadDocumentEntity? entity) =>
      entity != null &&
      const {
        CadDocumentEntityKind.section,
        CadDocumentEntityKind.sketch,
        CadDocumentEntityKind.curve,
        CadDocumentEntityKind.boundary,
        CadDocumentEntityKind.edge,
        CadDocumentEntityKind.wire,
      }.contains(entity.kind);

  List<Sketch> get _selectedSketches {
    final api = sketchApi;
    if (api == null) return const [];
    final selected = runtime.selection;
    final result = api.sketches
        .where((sketch) => selected.contains(sketch.id))
        .toList(growable: false);
    if (result.isNotEmpty) return result;
    if (selected.isNotEmpty) return const [];
    final active = activeSketch;
    return active == null ? const [] : [active];
  }

  Future<List<ShapeHandle>> _selectedProfessionalInputHandles(
    ProfessionalSurfaceTool tool,
  ) async {
    final result = <ShapeHandle>[];
    final document = runtime.document;
    for (final id in runtime.selection) {
      final entity = document?.entities[id];
      if (entity == null) continue;
      ShapeHandle? handle = entity.shape;
      if (handle == null && entity.kind == CadDocumentEntityKind.section) {
        handle = await _ensureSectionWire(entity);
      }
      if (handle != null &&
          !result.any((item) => item.persistentId == handle!.persistentId)) {
        result.add(await runtime.loadShape(handle));
      }
    }
    for (final sketch in _selectedSketches) {
      final persisted = runtime.document?.entities['curve:${sketch.id}']?.shape;
      if (persisted != null &&
          result.any(
            (handle) => handle.persistentId == persisted.persistentId,
          )) {
        continue;
      }
      result.add(await _ensureSketchWire(sketch));
    }
    return result;
  }

  Future<ShapeHandle> _ensureSectionWire(CadDocumentEntity section) async {
    final curveId = 'curve:${section.id}';
    final existing = runtime.document?.entities[curveId]?.shape;
    final revision = (section.data['revision'] as num?)?.toInt() ?? 1;
    if (existing != null && existing.revision == revision) {
      return runtime.loadShape(existing);
    }
    final sectionData = section.data['section'] as Map?;
    final rawSegments = sectionData?['segments'] as List? ?? const [];
    final points = <SketchVector>[];
    for (final raw in rawSegments) {
      if (raw is! List || raw.length < 2) continue;
      for (final endpoint in raw.take(2)) {
        final point = SketchVector.fromJson(endpoint);
        if (points.isEmpty || _sketchDistance(points.last, point) > 1e-9) {
          points.add(point);
        }
      }
    }
    if (points.length < 2) {
      throw StateError(
        '${section.data['name'] ?? section.id} has no usable curve.',
      );
    }
    return _createWireFromPoints(
      sourceId: section.id,
      sourceName: section.data['name'] as String? ?? section.id,
      sourceRevision: revision,
      points: points,
      curveType: ProfessionalCurveType.section,
      color: 'sectionBlue',
    );
  }

  Future<ShapeHandle> _ensureSketchWire(Sketch sketch) async {
    final curveId = 'curve:${sketch.id}';
    final existing = runtime.document?.entities[curveId]?.shape;
    final hasOfficialWire = runtime.document?.entities.values.any(
      (entity) =>
          entity.kind == CadDocumentEntityKind.wire &&
          (entity.data['topology'] as Map?)?['supportGeometryId'] == curveId,
    );
    if (existing != null &&
        hasOfficialWire == true &&
        existing.revision == sketch.version &&
        existing.metadata['sourceEntityId'] == sketch.id) {
      return runtime.loadShape(existing);
    }
    final points = _globalSketchPoints(sketch);
    if (points.length < 2) {
      throw StateError('${sketch.name} does not contain a usable curve.');
    }
    return _createWireFromPoints(
      sourceId: sketch.id,
      sourceName: sketch.name,
      sourceRevision: sketch.version,
      points: points,
      curveType: sketch.entityIds.length == 1
          ? ProfessionalCurveType.spline3d
          : ProfessionalCurveType.composite,
      color: sketch.entityIds.length == 1 ? 'splineMagenta' : 'polylineBlue',
    );
  }

  List<SketchVector> _globalSketchPoints(Sketch sketch) {
    final points = <SketchVector>[];
    for (final id in sketch.entityIds) {
      final entity = sketchApi?.entity(id);
      if (entity == null) continue;
      final sampled = _surfaceInputPoints(entity);
      for (final point in sampled) {
        final global = sketch.coordinates.localToGlobal(point);
        if (points.isEmpty || _sketchDistance(points.last, global) > 1e-9) {
          points.add(global);
        }
      }
    }
    return points;
  }

  Future<ShapeHandle> _createWireFromPoints({
    required String sourceId,
    required String sourceName,
    required int sourceRevision,
    required List<SketchVector> points,
    required ProfessionalCurveType curveType,
    required String color,
    bool materializeDocumentEntity = false,
  }) async {
    final kernel = runtime.kernels.active;
    final projectId = runtime.document?.projectId;
    if (projectId == null) throw StateError('Open a project first.');
    final transaction = KernelTransaction(
      'wire-${DateTime.now().microsecondsSinceEpoch}',
      projectId,
      kernel.descriptor.id,
      DateTime.now(),
      TransactionStatus.active,
      const [],
    );
    await kernel.begin(transaction);
    try {
      final vertices = <ShapeHandle>[];
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        vertices.add(
          await kernel.create(
            'CREATE VERTEX',
            {'x': point.x, 'y': point.y, 'z': point.z},
            persistentId: '$sourceId:vertex:$index:r$sourceRevision',
            expectedType: CADShapeType.vertex,
            transaction: transaction,
          ),
        );
      }
      final edges = <ShapeHandle>[];
      for (var index = 0; index + 1 < vertices.length; index++) {
        edges.add(
          await kernel.create(
            'CREATE EDGE',
            {'start': vertices[index], 'end': vertices[index + 1]},
            persistentId: '$sourceId:edge:$index:r$sourceRevision',
            expectedType: CADShapeType.edge,
            transaction: transaction,
          ),
        );
      }
      final native = await kernel.create(
        'CREATE WIRE',
        {'edges': edges},
        persistentId: '$sourceId:wire:r$sourceRevision',
        expectedType: CADShapeType.wire,
        transaction: transaction,
      );
      await kernel.commit(transaction);
      final wire = ShapeHandle.reference(
        persistentId: native.persistentId,
        kernelId: native.kernelId,
        type: native.type,
        revision: sourceRevision,
        fingerprint: native.fingerprint,
        metadata: {...native.metadata, 'sourceEntityId': sourceId},
      );
      final now = DateTime.now().toUtc();
      final curve = ProfessionalCurve(
        id: 'curve:$sourceId',
        name: '$sourceName Curve',
        type: curveType,
        points: points.map((point) => point.toJson()).toList(),
        handle: wire,
        revision: sourceRevision,
        sourceEntityId: sourceId,
        associationState: CurveAssociationState.current,
        continuity: CurveContinuity.g0,
        color: color,
        createdAt: now,
        updatedAt: now,
        metadata: {
          'length': _polylineLength(points),
          'pointCount': points.length,
          'sourceRevision': sourceRevision,
        },
      );
      // Geometry Input Resolver materialization is transactional and invisible
      // to the operator. Only explicitly created Curve/Topology entities and
      // the accepted surface result belong in CadDocument.
      if (!materializeDocumentEntity) return wire;
      final vertexTopologyIds = <String>[];
      final topologyEntities = <CadDocumentEntity>[];
      for (var index = 0; index < vertices.length; index++) {
        final handle = vertices[index];
        await runtime.persistShape(handle);
        final topology = TopologicalEntity(
          id: 'vertex:${handle.persistentId}',
          name: '${curve.name} Vertex ${index + 1}',
          type: TopologicalEntityType.vertex,
          handle: handle,
          revision: sourceRevision,
          supportGeometryId: curve.id,
          tolerance: 1e-7,
          createdAt: now,
          updatedAt: now,
          metadata: {'position': points[index].toJson()},
        );
        vertexTopologyIds.add(topology.id);
        topologyEntities.add(
          CadDocumentEntity(
            id: topology.id,
            kind: CadDocumentEntityKind.vertex,
            shape: handle,
            data: {
              'name': topology.name,
              'topology': topology.toJson(),
              'sceneKind': 'point',
              'sceneVisible': false,
              'sceneGeometry': {'position': points[index].toJson()},
            },
          ),
        );
      }
      final edgeTopologyIds = <String>[];
      for (var index = 0; index < edges.length; index++) {
        final handle = edges[index];
        await runtime.persistShape(handle);
        final topology = TopologicalEntity(
          id: 'edge:${handle.persistentId}',
          name: '${curve.name} Edge ${index + 1}',
          type: TopologicalEntityType.edge,
          handle: handle,
          revision: sourceRevision,
          vertexIds: [vertexTopologyIds[index], vertexTopologyIds[index + 1]],
          supportGeometryId: curve.id,
          tolerance: 1e-7,
          createdAt: now,
          updatedAt: now,
        );
        edgeTopologyIds.add(topology.id);
        topologyEntities.add(
          CadDocumentEntity(
            id: topology.id,
            kind: CadDocumentEntityKind.edge,
            shape: handle,
            data: {
              'name': topology.name,
              'topology': topology.toJson(),
              'sceneKind': 'curve',
              'sceneVisible': false,
              'sceneGeometry': {
                'points': [points[index].toJson(), points[index + 1].toJson()],
              },
            },
          ),
        );
      }
      final wireTopology = TopologicalEntity(
        id: 'wire:${wire.persistentId}',
        name: '${curve.name} Wire',
        type: TopologicalEntityType.wire,
        handle: wire,
        revision: sourceRevision,
        vertexIds: vertexTopologyIds,
        edgeIds: edgeTopologyIds,
        supportGeometryId: curve.id,
        closed: _sketchDistance(points.first, points.last) <= 1e-7,
        manifold: true,
        tolerance: 1e-7,
        createdAt: now,
        updatedAt: now,
      );
      topologyEntities.add(
        CadDocumentEntity(
          id: wireTopology.id,
          kind: CadDocumentEntityKind.wire,
          shape: wire,
          data: {
            'name': wireTopology.name,
            'topology': wireTopology.toJson(),
            'sceneKind': 'curve',
            'sceneVisible': false,
            'sceneGeometry': {'points': curve.points, 'handle': wire.toJson()},
          },
        ),
      );
      await runtime.mutate(
        command: 'topology.materialize-wire',
        upsert: topologyEntities,
      );
      await runtime.upsertEntity(
        command: 'wireframe.from-sketch',
        kind: CadDocumentEntityKind.curve,
        entity: CadSceneEntity(
          id: curve.id,
          kind: CadSceneEntityKind.curve,
          geometry: {
            'handle': wire.toJson(),
            'points': curve.points,
            'displayColor': curve.color,
            'strokeWidth': 2.5,
          },
        ),
        shape: wire,
        data: {
          'name': curve.name,
          'group': 'Curves',
          'curve': curve.toJson(),
          'sourceEntityId': sourceId,
          'associationState': curve.associationState.name,
        },
      );
      runtime.select({curve.id});
      return wire;
    } catch (_) {
      await kernel.rollback(transaction);
      rethrow;
    }
  }

  List<SketchVector> _surfaceInputPoints(SketchEntity entity) =>
      switch (entity) {
        SketchPoint() => [SketchVector.fromJson(entity.parameters['point'])],
        SketchLine() => [
          SketchVector.fromJson(entity.parameters['start']),
          SketchVector.fromJson(entity.parameters['end']),
        ],
        SketchSpline() =>
          ((entity.parameters['sampledPoints'] ?? entity.parameters['points'])
                  as List)
              .map(SketchVector.fromJson)
              .toList(growable: false),
        SketchCircle() => _sampleSketchEllipse(entity, circular: true),
        SketchEllipse() => _sampleSketchEllipse(entity),
        SketchArc() => _sampleSketchArc(entity),
        _ => const [],
      };

  List<SketchVector> _sampleSketchEllipse(
    SketchEntity entity, {
    bool circular = false,
  }) {
    final center = SketchVector.fromJson(entity.parameters['center']);
    final rx = (entity.parameters[circular ? 'radius' : 'radiusX'] as num)
        .toDouble();
    final ry = circular ? rx : (entity.parameters['radiusY'] as num).toDouble();
    return List.generate(65, (index) {
      final angle = math.pi * 2 * index / 64;
      return SketchVector(
        center.x + rx * math.cos(angle),
        center.y + ry * math.sin(angle),
      );
    });
  }

  List<SketchVector> _sampleSketchArc(SketchEntity entity) {
    final center = SketchVector.fromJson(entity.parameters['center']);
    final radius = (entity.parameters['radius'] as num).toDouble();
    final start = (entity.parameters['startAngle'] as num).toDouble();
    final end = (entity.parameters['endAngle'] as num).toDouble();
    return List.generate(33, (index) {
      final angle = start + (end - start) * index / 32;
      return SketchVector(
        center.x + radius * math.cos(angle),
        center.y + radius * math.sin(angle),
      );
    });
  }

  double _sketchDistance(SketchVector a, SketchVector b) {
    final dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  double _polylineLength(List<SketchVector> points) {
    var length = 0.0;
    for (var index = 0; index + 1 < points.length; index++) {
      length += _sketchDistance(points[index], points[index + 1]);
    }
    return length;
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
      if (confirmed.tool == ProfessionalSurfaceTool.offsetWalls &&
          confirmed.parameters['offsetMode'] == 'replace') {
        final sources =
            (confirmed.parameters['sourceEntityIds'] as List? ?? const [])
                .whereType<String>()
                .where((id) => id != confirmed.id)
                .toList(growable: false);
        if (sources.isNotEmpty) {
          await runtime.mutate(
            command: 'surface.offset.replace-source',
            remove: sources,
          );
        }
      }
      final report = professionalSurfaceOperationReport;
      if (report != null) {
        runtime.write('surface.operationReport', {
          ...report,
          'state': 'Applied',
        });
      }
      professionalSurfacePreview = null;
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> updateProfessionalSurfacePreview({
    Map<String, dynamic> parameters = const {},
    SurfaceContinuity? continuity,
  }) async {
    final api = professionalSurfaceApi;
    final current = professionalSurfacePreview;
    if (api == null || current == null) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      runtime.hideTransient('preview:${current.definition.id}');
      final updated = await api.preview(
        current.definition.id,
        parameters: {...current.definition.parameters, ...parameters},
        continuity: continuity,
      );
      professionalSurfacePreview = updated;
      final handle = updated.definition.handle;
      if (handle != null) {
        await runtime.showTransientShape(
          _professionalSurfaceVisual(updated.definition, preview: true),
          handle,
        );
        await _reportProfessionalSurfaceResult(
          tool: updated.definition.tool,
          handle: handle,
          affectedEntities: updated.definition.references.length,
          parameters: updated.definition.parameters,
          state: 'Preview',
        );
      }
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
    final report = professionalSurfaceOperationReport;
    if (report != null) {
      runtime.write('surface.operationReport', {
        ...report,
        'state': 'Cancelled',
      });
    }
    professionalSurfacePreview = null;
    notifyListeners();
  }

  Future<void> previewProfessionalSurfaceEdit(
    ProfessionalSurfaceTool tool,
  ) async {
    final api = professionalSurfaceApi;
    final selected = selectedProfessionalSurface;
    if (api == null || selected?.handle == null) {
      throw StateError('Select a committed Surface before ${tool.name}.');
    }
    final references = <ShapeHandle>[
      await runtime.loadShape(selected!.handle!),
    ];
    if ({
      ProfessionalSurfaceTool.match,
      ProfessionalSurfaceTool.split,
      ProfessionalSurfaceTool.join,
      ProfessionalSurfaceTool.offsetWalls,
      ProfessionalSurfaceTool.boundaryExtend,
      ProfessionalSurfaceTool.boundaryTrim,
      ProfessionalSurfaceTool.unsewFace,
      ProfessionalSurfaceTool.unsewSelected,
      ProfessionalSurfaceTool.unsewAll,
      ProfessionalSurfaceTool.replaceFace,
      ProfessionalSurfaceTool.deleteFace,
    }.contains(tool)) {
      for (final handle in geometrySelection.shapeHandles) {
        if (handle.persistentId != selected.handle!.persistentId) {
          references.add(await runtime.loadShape(handle));
        }
      }
      if ({
            ProfessionalSurfaceTool.match,
            ProfessionalSurfaceTool.split,
            ProfessionalSurfaceTool.join,
            ProfessionalSurfaceTool.boundaryTrim,
            ProfessionalSurfaceTool.unsewFace,
            ProfessionalSurfaceTool.unsewSelected,
            ProfessionalSurfaceTool.replaceFace,
            ProfessionalSurfaceTool.deleteFace,
          }.contains(tool) &&
          references.length < 2) {
        throw StateError('${tool.name} requires a target and a tool shape.');
      }
      if (tool == ProfessionalSurfaceTool.replaceFace &&
          references.length < 3) {
        throw StateError(
          'Replace Face requires owner, Face to replace and replacement Face.',
        );
      }
      if ({
            ProfessionalSurfaceTool.unsewFace,
            ProfessionalSurfaceTool.unsewSelected,
            ProfessionalSurfaceTool.deleteFace,
          }.contains(tool) &&
          references.length < 2) {
        throw StateError('${tool.name} requires selected Face topology.');
      }
    }
    final parameters = <String, dynamic>{
      'shapeHandles': references.map((item) => item.toJson()).toList(),
      if (tool == ProfessionalSurfaceTool.extend) ...{
        'length': 10.0,
        'continuity': 1,
        'inU': true,
        'after': true,
      },
      if (tool == ProfessionalSurfaceTool.trim) ...{
        'uMin': 0.0,
        'uMax': 0.9,
        'vMin': 0.0,
        'vMax': 0.9,
      },
      if (tool == ProfessionalSurfaceTool.offset) 'distance': 2.0,
      if (tool == ProfessionalSurfaceTool.offsetWalls) ...{
        'distance': 2.0,
        'tolerance': 1e-4,
        'join': 'arc',
        'offsetMode': 'walls',
        'direction': 'outside',
        'insideDistance': 2.0,
        'outsideDistance': 2.0,
        'wallBoundaryIds': const <String>[],
        'openBoundaryIds': references
            .skip(1)
            .map((handle) => handle.persistentId)
            .toList(growable: false),
        'closeResult': false,
      },
      if (tool == ProfessionalSurfaceTool.boundaryExtend) ...{
        'mode': references.length > 1 ? 'upToGeometry' : 'byLength',
        'length': 10.0,
        'continuity': 1,
        'inU': true,
        'after': true,
        'tolerance': 1e-6,
      },
      if (tool == ProfessionalSurfaceTool.boundaryTrim) ...{
        'tolerance': 1e-7,
        'keepPointX': activePick?.hit.point.x ?? 0,
        'keepPointY': activePick?.hit.point.y ?? 0,
        'keepPointZ': activePick?.hit.point.z ?? 0,
        'hasKeepPoint': activePick != null,
      },
      if (tool == ProfessionalSurfaceTool.match) ...{
        'continuity': 1,
        'pointsOnCurve': 10,
        'tolerance3d': 1e-4,
        'angularTolerance': 1e-2,
        'curvatureTolerance': 1e-1,
      },
    };
    busy = true;
    error = null;
    notifyListeners();
    try {
      final draft = api.begin(
        tool: tool,
        references: references.map((item) => item.persistentId).toList(),
        parameters: parameters,
        continuity: tool == ProfessionalSurfaceTool.match
            ? SurfaceContinuity.g1
            : SurfaceContinuity.g0,
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
        await _reportProfessionalSurfaceResult(
          tool: tool,
          handle: handle,
          affectedEntities: references.length,
          parameters: parameters,
          state: 'Preview',
        );
      }
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> analyzeSelectedProfessionalSurface(
    SurfaceAnalysisMode mode,
  ) async {
    final api = professionalSurfaceApi;
    final selected = selectedProfessionalSurface;
    if (api == null || selected == null) {
      throw StateError('Select a committed Surface for analysis.');
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final analysis = await api.analyze(selected.id, {mode});
      runtime.write('surface.analysis', analysis);
      final visual = runtime.scene.find(selected.id);
      if (visual != null) {
        runtime.scene.upsert(
          CadSceneEntity(
            id: visual.id,
            kind: visual.kind,
            geometry: {
              ...visual.geometry,
              'surfaceAnalysisMode': mode.name,
              'surfaceAnalysis': analysis,
            },
            visible: visual.visible,
            selected: visual.selected,
            transparent: visual.transparent,
          ),
        );
      }
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clearProfessionalSurfaceAnalysis() {
    final selected = selectedProfessionalSurface;
    if (selected == null) return;
    final visual = runtime.scene.find(selected.id);
    if (visual != null) {
      final geometry = Map<String, dynamic>.from(visual.geometry)
        ..remove('surfaceAnalysisMode')
        ..remove('surfaceAnalysis');
      runtime.scene.upsert(
        CadSceneEntity(
          id: visual.id,
          kind: visual.kind,
          geometry: geometry,
          visible: visual.visible,
          selected: visual.selected,
          transparent: visual.transparent,
        ),
      );
    }
    runtime.write('surface.analysis', null);
    notifyListeners();
  }

  Future<void> validateSelectedProfessionalSurface() async {
    final api = professionalSurfaceApi;
    final selected = selectedProfessionalSurface;
    if (api == null || selected?.handle == null) {
      throw StateError('Select a committed Surface for validation.');
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final handle = await runtime.loadShape(selected!.handle!);
      runtime.write(
        'surface.validation',
        await api.kernel.validate(handle, const {
          'brep',
          'topology',
          'tolerance',
          'manifold',
        }),
      );
      runtime.write('surface.validation.completed', true);
    } catch (value) {
      error = value.toString().replaceFirst('Bad state: ', '');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> undo() async {
    await commands.undo();
    await _synchronizeSketchScene();
    if (lineCommandActive) {
      previewPoints = const [];
      runtime.write('sketch.line.cursor', null);
      runtime.hideTransient('sketch-line-preview');
    }
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

    ReferenceEntity? recognizedReferenceCommandValue;
    register(
      id: 'reverse.reference.recognized',
      execute: (_) async {
        final primitive = hypotheses
            .where(
              (item) =>
                  decisions[item.recognition.id] ==
                  RecognitionDecision.accepted,
            )
            .firstOrNull;
        final context = activeContext;
        if (primitive == null || context?.region == null) {
          throw StateError('Accept a recognition hypothesis first.');
        }
        final winner = primitive.recognition.winner;
        final parameters = winner.parameters;
        ReferenceRecipe recipe;
        String name;
        if (winner.type.name == 'sphere') {
          final center = parameters['center'];
          if (center is! List || center.length != 3) {
            throw StateError('Recognized sphere has no valid center.');
          }
          name = 'Recognized Sphere Center';
          recipe = ReferenceRecipe(
            'point',
            {'method': 'explicit', 'point': center},
            [context!.region!.id],
          );
        } else if ({'cylinder', 'cone', 'torus'}.contains(winner.type.name)) {
          final origin = parameters['origin'] ?? parameters['center'];
          final direction = parameters['axis'];
          if (origin is! List ||
              origin.length != 3 ||
              direction is! List ||
              direction.length != 3) {
            throw StateError(
              'Recognized ${winner.type.name} has no valid axis.',
            );
          }
          final second = List<double>.generate(
            3,
            (index) =>
                (origin[index] as num).toDouble() +
                (direction[index] as num).toDouble(),
          );
          name = 'Recognized ${winner.type.name} Axis';
          recipe = ReferenceRecipe(
            'axis',
            {
              'method': 'twoPoints',
              'points': [origin, second],
            },
            [context!.region!.id],
          );
        } else {
          throw StateError(
            'Use Create Plane Reference for planar recognition.',
          );
        }
        recognizedReferenceCommandValue = await _referenceApi.create(
          projectId: configuredProjectId!,
          name: name,
          mode: ReferenceMode.staticReference,
          recipe: recipe,
        );
        activeReference = recognizedReferenceCommandValue;
        await _upsertReference(
          recognizedReferenceCommandValue!,
          command: 'reference.recognition',
        );
        return recognizedReferenceCommandValue!.id;
      },
      undo: (_) async {
        final value = recognizedReferenceCommandValue;
        if (value != null) {
          await _referenceApi.delete(value);
          await runtime.removeEntity(value.id, command: 'reference.undo');
        }
        return 'recognized reference removed';
      },
      redo: (_) async {
        final value = recognizedReferenceCommandValue;
        if (value == null) {
          throw StateError('No recognized reference to restore.');
        }
        await _referenceApi.restore(value);
        await _upsertReference(value, command: 'reference.redo');
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
        final x =
            plane.xDirection ??
            normal
                .cross(
                  normal.z.abs() < .9
                      ? const Vec3(0, 0, 1)
                      : const Vec3(0, 1, 0),
                )
                .normalized;
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
        final plane = activeSketchPlane;
        final planeId = activeSketchPlaneId;
        if (plane == null || planeId == null) {
          throw StateError('Select a plane before opening Sketch.');
        }
        final supportEntity = runtime.document?.entities[planeId];
        final planeType = switch (supportEntity?.data['name']) {
          'XY Plane' => SketchPlaneType.xy,
          'YZ Plane' => SketchPlaneType.yz,
          'XZ Plane' => SketchPlaneType.zx,
          _ => SketchPlaneType.faceReference,
        };
        sketchCommandValue = SketchBridge(sketchApi!).openOnSupport(
          referenceId: planeId,
          geometry: plane,
          name: _nextSketchName(),
          planeType: planeType,
        );
        sketchCommandValue!.metadata.addAll({
          'supportEntityId': planeId,
          'supportKind': supportEntity?.kind.name ?? 'reference',
          'meshIndependent': true,
        });
        activeSketch = sketchCommandValue;
        stage = SketchSurfaceStage.sketchActive;
        await _synchronizeSketchScene();
        // The support remains visibly active for the entire Sketch session.
        runtime.select({planeId, sketchCommandValue!.id});
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
        final operationParameters = parameters['operationParameters'] is Map
            ? Map<String, dynamic>.from(
                parameters['operationParameters']! as Map,
              )
            : null;
        final operation = editorApi!.preview(
          tool,
          points,
          parameters: operationParameters,
        );
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

    register(
      id: 'reverse.sketch.delete',
      execute: (parameters) async {
        final ids = (parameters['ids']! as List).cast<String>();
        editorApi!.preview(SketchToolType.delete, const []);
        editorApi!.edit(SketchToolType.delete, ids);
        await _synchronizeSketchScene();
        return '${ids.length} Sketch entity(s) deleted';
      },
      undo: (_) async {
        editorApi!.undo();
        await _synchronizeSketchScene();
        return 'Sketch deletion undone';
      },
      redo: (_) async {
        editorApi!.redo();
        await _synchronizeSketchScene();
        return 'Sketch deletion restored';
      },
    );

    register(
      id: 'reverse.sketch.edit',
      execute: (parameters) async {
        final tool = SketchToolType.values.byName(
          parameters['tool']! as String,
        );
        final ids = (parameters['ids']! as List).cast<String>();
        final trimMode = parameters['trimMode'] as String?;
        if (tool == SketchToolType.trim && trimMode == 'endpoint') {
          editorApi!.trimEndpointToNearestIntersection(
            ids.single,
            SketchVector.fromJson(parameters['point']),
          );
          await _synchronizeSketchScene();
          return 'trim endpoint completed';
        }
        if (tool == SketchToolType.trim && trimMode == 'keepSides') {
          final points = (parameters['points']! as List)
              .map(SketchVector.fromJson)
              .toList(growable: false);
          editorApi!.trimIntersection(ids[0], points[0], ids[1], points[1]);
          await _synchronizeSketchScene();
          return 'intersection trim completed';
        }
        final before = sketchApi!.engine.entities.keys.toSet();
        editorApi!.preview(tool, const []);
        editorApi!.edit(
          tool,
          ids,
          value: (parameters['value'] as num?)?.toDouble() ?? 1,
          parameters: {
            if (parameters['point'] != null) 'point': parameters['point'],
            'autoTrim': parameters['autoTrim'] as bool? ?? true,
          },
        );
        final created = sketchApi!.engine.entities.keys
            .where((id) => !before.contains(id))
            .toList(growable: false);
        for (final id in created) {
          final entity = sketchApi!.entity(id)!;
          entity.metadata.addAll({
            'featureType': tool.name,
            'featureValue': (parameters['value'] as num?)?.toDouble() ?? 1,
            'sourceEntityIds': ids,
            'autoTrim': parameters['autoTrim'] as bool? ?? true,
            'authoringRoot':
                tool == SketchToolType.fillet || tool == SketchToolType.chamfer,
            'authoringWorkspace': 'Sketch',
          });
        }
        parameters['createdIds'] = created;
        await _synchronizeSketchScene();
        return '${tool.name} completed';
      },
      undo: (_) async {
        if (editorApi?.undo() != true) {
          throw StateError('No Sketch edit is available to undo.');
        }
        await _synchronizeSketchScene();
        return 'Sketch edit undone';
      },
      redo: (_) async {
        if (editorApi?.redo() != true) {
          throw StateError('No Sketch edit is available to redo.');
        }
        await _synchronizeSketchScene();
        return 'Sketch edit restored';
      },
    );

    register(
      id: 'reverse.sketch.parameters',
      execute: (parameters) async {
        final id = parameters['id']! as String;
        final values = (parameters['values']! as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        );
        final entity = sketchApi?.entity(id);
        if (entity == null) throw StateError('Unknown Sketch entity: $id');
        _validateConstrainedParameterEdit(entity, values);
        parameters['entityVersionBefore'] = entity.version;
        final connections = _currentSketchConnections();
        sketchApi!.engine.transaction('safe-parametric-edit', () {
          sketchApi!.updateParameters(id, values);
          _assertSketchConnectionsPreserved(connections);
        });
        await _synchronizeSketchScene();
        runtime.select({id});
        return id;
      },
      undo: (parameters) async {
        final id = parameters['id']! as String;
        if (sketchApi?.engine.undo() != true) {
          throw StateError('No parametric edit is available to undo.');
        }
        await _synchronizeSketchScene();
        runtime.select({id});
        return '$id parameters restored';
      },
      redo: (parameters) async {
        final id = parameters['id']! as String;
        if (sketchApi?.engine.redo() != true) {
          throw StateError('No parametric edit is available to redo.');
        }
        await _synchronizeSketchScene();
        runtime.select({id});
        return '$id parameters reapplied';
      },
    );

    register(
      id: 'reverse.sketch.feature.parameters',
      execute: (parameters) async {
        final id = parameters['id']! as String;
        final value = (parameters['value']! as num).toDouble();
        editorApi!.editCornerFeature(id, value);
        await _synchronizeSketchScene();
        runtime.select({id});
        return id;
      },
      undo: (_) async {
        if (editorApi?.undo() != true) {
          throw StateError('No feature edit is available to undo.');
        }
        await _synchronizeSketchScene();
        return 'feature parameter restored';
      },
      redo: (_) async {
        if (editorApi?.redo() != true) {
          throw StateError('No feature edit is available to redo.');
        }
        await _synchronizeSketchScene();
        return 'feature parameter reapplied';
      },
    );

    register(
      id: 'reverse.sketch.dimension.create',
      execute: (parameters) async {
        final dimension = constraintApi!.createDrivingDimension(
          type: SketchDimensionType.values.byName(
            parameters['type']! as String,
          ),
          references: (parameters['references']! as List).cast<String>(),
          value: (parameters['value']! as num).toDouble(),
          anchorReference: parameters['anchorReference'] as String?,
          labelX: (parameters['labelX'] as num?)?.toDouble() ?? 0,
          labelY: (parameters['labelY'] as num?)?.toDouble() ?? 0,
        );
        parameters['id'] = dimension.id;
        await persist();
        await _synchronizeSketchScene();
        return dimension.id;
      },
      undo: (_) async {
        if (constraintApi?.undoDimensionEdit() != true) {
          throw StateError('No dimension creation is available to undo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension removed';
      },
      redo: (_) async {
        if (constraintApi?.redoDimensionEdit() != true) {
          throw StateError('No dimension creation is available to redo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension restored';
      },
    );
    register(
      id: 'reverse.sketch.dimension.edit',
      execute: (parameters) async {
        constraintApi!.driveDimension(
          parameters['id']! as String,
          (parameters['value']! as num).toDouble(),
        );
        await persist();
        await _synchronizeSketchScene();
        return parameters['id']!;
      },
      undo: (_) async {
        if (constraintApi?.undoDimensionEdit() != true) {
          throw StateError('No dimension edit is available to undo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension value restored';
      },
      redo: (_) async {
        if (constraintApi?.redoDimensionEdit() != true) {
          throw StateError('No dimension edit is available to redo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension value reapplied';
      },
    );
    register(
      id: 'reverse.sketch.dimension.delete',
      execute: (parameters) async {
        constraintApi!.deleteDimension(parameters['id']! as String);
        await persist();
        await _synchronizeSketchScene();
        return parameters['id']!;
      },
      undo: (_) async {
        if (constraintApi?.engine.undo() != true) {
          throw StateError('No dimension deletion is available to undo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension restored';
      },
      redo: (_) async {
        if (constraintApi?.engine.redo() != true) {
          throw StateError('No dimension deletion is available to redo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension deleted';
      },
    );
    register(
      id: 'reverse.sketch.dimension.move',
      execute: (parameters) async {
        constraintApi!.updateDimension(
          parameters['id']! as String,
          labelX: (parameters['x']! as num).toDouble(),
          labelY: (parameters['y']! as num).toDouble(),
        );
        await persist();
        await _synchronizeSketchScene();
        return parameters['id']!;
      },
      undo: (_) async {
        if (constraintApi?.engine.undo() != true) {
          throw StateError('No dimension move is available to undo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension label restored';
      },
      redo: (_) async {
        if (constraintApi?.engine.redo() != true) {
          throw StateError('No dimension move is available to redo.');
        }
        await persist();
        await _synchronizeSketchScene();
        return 'dimension label moved';
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
      id: 'reverse.sketch.constraint.delete',
      execute: (parameters) async {
        final id = parameters['id']! as String;
        constraintApi!.delete(id);
        await _synchronizeSketchScene();
        return 'constraint deleted';
      },
      undo: (_) async {
        if (constraintApi?.engine.undo() != true) {
          throw StateError('No constraint deletion is available to undo.');
        }
        await _synchronizeSketchScene();
        return 'constraint restored';
      },
      redo: (_) async {
        if (constraintApi?.engine.redo() != true) {
          throw StateError('No constraint deletion is available to redo.');
        }
        await _synchronizeSketchScene();
        return 'constraint deleted again';
      },
    );

    register(
      id: 'reverse.sketch.finish',
      execute: (_) async {
        runtime.hideTransient('sketch-line-preview');
        await persist();
        sketchApi!.closeSketch();
        stage = SketchSurfaceStage.sketchFinished;
        // Publish the committed, closed-Sketch state before returning control
        // to the workspace. synchronizeChanges awaits the SceneGraph update.
        await _synchronizeSketchScene();
        await runtime.transitionFeature(
          activeSketch!.id,
          FeatureLifecycleState.closed,
          command: 'feature.close',
        );
        runtime.select({activeSketch!.id});
        return activeSketch!.id;
      },
      undo: (_) async {
        sketchApi!.openSketch(activeSketch!.id);
        stage = SketchSurfaceStage.sketchActive;
        await _synchronizeSketchScene();
        await runtime.transitionFeature(
          activeSketch!.id,
          FeatureLifecycleState.editing,
          command: 'feature.close.undo',
        );
        return activeSketch!.id;
      },
      redo: (_) async {
        sketchApi!.closeSketch();
        stage = SketchSurfaceStage.sketchFinished;
        await _synchronizeSketchScene();
        await runtime.transitionFeature(
          activeSketch!.id,
          FeatureLifecycleState.closed,
          command: 'feature.close.redo',
        );
        return activeSketch!.id;
      },
    );

    register(
      id: 'reverse.surface.preview',
      execute: (_) async {
        if (!sketchReadyForSurface) throw StateError(sketchSurfaceBlockReason);
        final sketch = activeSketch ?? (throw StateError('No active Sketch.'));
        runtime.showTransient(
          _sketchSurfacePreviewBuilder.build(
            entities: sketchEntities,
            coordinates: sketch.coordinates,
          ),
        );
        runtime.write('sketch.surfacePreview.active', true);
        surfacePlan = null;
        stage = SketchSurfaceStage.surfacePreview;
        return 'surface-preview';
      },
      undo: (_) async {
        runtime.hideTransient('surface-preview');
        runtime.write('sketch.surfacePreview.active', false);
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
    _commandsRegistered = true;
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
    data: {
      'name': reference.name,
      'reference': ReferenceSerializer.toJson(reference),
    },
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
  }) async {
    final recordedSources =
        (value.parameters['sourceEntityIds'] as List? ?? const [])
            .whereType<String>()
            .toSet();
    final sourceIds = recordedSources.isNotEmpty
        ? recordedSources.toList(growable: false)
        : runtime.document?.entities.values
                  .where(
                    (entity) =>
                        entity.shape != null &&
                        value.references.contains(entity.shape!.persistentId),
                  )
                  .map((entity) => entity.id)
                  .toSet()
                  .toList(growable: false) ??
              const <String>[];
    await runtime.upsertEntity(
      command: command,
      kind: CadDocumentEntityKind.surface,
      entity: _professionalSurfaceVisual(value),
      shape: value.handle,
      officialShape: value.handle != null,
      data: {
        'name': value.name,
        'professionalSurface': value.toJson(),
        'sourceEntityIds': sourceIds,
        'associationState': 'current',
      },
    );
    final handle = value.handle;
    if (handle == null) return;
    final now = DateTime.now().toUtc();
    final outerWireIds = sourceIds
        .where((id) {
          final kind = runtime.document?.entities[id]?.kind;
          return kind == CadDocumentEntityKind.wire ||
              kind == CadDocumentEntityKind.boundary ||
              kind == CadDocumentEntityKind.curve;
        })
        .toList(growable: false);
    final topologyType = switch (handle.type) {
      CADShapeType.solid => TopologicalEntityType.solid,
      CADShapeType.shell => TopologicalEntityType.shell,
      _ => TopologicalEntityType.face,
    };
    final documentKind = switch (topologyType) {
      TopologicalEntityType.solid => CadDocumentEntityKind.solid,
      TopologicalEntityType.shell => CadDocumentEntityKind.shell,
      _ => CadDocumentEntityKind.face,
    };
    final topologyPrefix = topologyType.name;
    final face = TopologicalEntity(
      id: '$topologyPrefix:${value.id}',
      name: '${value.name} ${topologyType.name}',
      type: topologyType,
      handle: handle,
      revision: value.revision,
      supportGeometryId: value.id,
      outerWireId: topologyType == TopologicalEntityType.face
          ? outerWireIds.firstOrNull
          : null,
      continuity: switch (value.continuity) {
        SurfaceContinuity.g0 => TopologicalContinuity.g0,
        SurfaceContinuity.g1 => TopologicalContinuity.g1,
        SurfaceContinuity.g2 => TopologicalContinuity.g2,
      },
      createdAt: value.createdAt,
      updatedAt: now,
      metadata: {'sourceEntityIds': sourceIds, 'tool': value.tool.name},
    );
    await runtime.upsertEntity(
      command: '$command.face',
      kind: documentKind,
      entity: CadSceneEntity(
        id: face.id,
        kind: CadSceneEntityKind.surface,
        geometry: {'handle': handle.toJson(), 'surfaceId': value.id},
      ),
      shape: handle,
      data: {
        'name': face.name,
        'topology': face.toJson(),
        'sceneVisible': false,
      },
    );
  }

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
    final allSketches = sketchApi?.sketches ?? const <Sketch>[];
    final allSketchEntities = <SketchEntity>[];
    final sketchByEntityId = <String, Sketch>{};
    final sketchEntityNames = <String, String>{};
    for (final sketch in allSketches) {
      final counts = <SketchEntityType, int>{};
      for (final id in sketch.entityIds) {
        final entity = sketchApi?.entity(id);
        if (entity != null) {
          // Explorer visibility is persisted by CadRuntime without rebuilding
          // Sketch geometry. Preserve that localized display state whenever a
          // later parametric edit republishes the Sketch document projection.
          final persistedVisibility =
              document.entities[id]?.data['sceneVisible'];
          if (persistedVisibility is bool) entity.visible = persistedVisibility;
          allSketchEntities.add(entity);
          sketchByEntityId[id] = sketch;
          final number = (counts[entity.type] ?? 0) + 1;
          counts[entity.type] = number;
          final prefix = switch (entity.type) {
            SketchEntityType.line =>
              entity.metadata['featureType'] == 'chamfer' ? 'Chamfer' : 'Line',
            SketchEntityType.circle => 'Circle',
            SketchEntityType.arc =>
              entity.metadata['featureType'] == 'fillet' ? 'Fillet' : 'Arc',
            _ => entity.type.name,
          };
          sketchEntityNames[id] = '$prefix${number.toString().padLeft(3, '0')}';
        }
      }
    }
    final currentIds = {
      ...allSketchEntities.map((item) => item.id),
      ...allSketches.map((item) => item.id),
    };
    final constraintIds = {
      ...constraints.map((item) => item.id),
      ...dimensions.map((item) => item.id),
    };
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
        ...allSketches.map(
          (sketch) => CadDocumentEntity(
            id: sketch.id,
            kind: CadDocumentEntityKind.sketch,
            data: {
              'name': sketch.name,
              'authoringRoot': true,
              'authoringWorkspace': 'Sketch',
              'group': 'Sketches',
              'sceneKind': 'sketch',
              'sceneVisible': sketch.metadata['visible'] as bool? ?? true,
              'revision': sketch.version,
              'sourceSectionId': sketch.metadata['sourceSectionId'],
              'associationState':
                  sketch.metadata['associationState'] ?? 'detached',
              'entityCount': sketch.entityIds.length,
              'constraintCount': constraints.length,
              'pointCount': sketch.metadata['pointCount'] ?? 0,
              'segmentCount': sketch.metadata['segmentCount'] ?? 0,
              'maximumError': sketch.metadata['maximumError'] ?? 0.0,
              'meanError': sketch.metadata['meanError'] ?? 0.0,
              'tolerance': sketch.metadata['tolerance'] ?? 0.0,
              'lastUpdatedAt': sketch.metadata['lastUpdatedAt'],
              'localCoordinateSystem': sketch.coordinates.toJson(),
              'geometricEntities': sketch.entityIds,
              'constraints': constraints.map((item) => item.id).toList(),
              'dimensions': dimensions.map((item) => item.id).toList(),
              'sketch': sketch.toJson(),
            },
          ),
        ),
        ...allSketchEntities.map((value) {
          final visual = _sketchScene.adapt(
            value,
            coordinates: sketchByEntityId[value.id]?.coordinates,
          );
          return CadDocumentEntity(
            id: value.id,
            kind: CadDocumentEntityKind.sketch,
            data: {
              'name': sketchEntityNames[value.id] ?? value.id,
              'parentSketchId': sketchByEntityId[value.id]?.id,
              'sketchEntity': value.toJson(),
              'authoringRoot': value.metadata['authoringRoot'] == true,
              'authoringWorkspace': value.metadata['authoringWorkspace'],
              'sceneKind': visual.kind.name,
              'sceneGeometry': visual.geometry,
              'sceneVisible':
                  value.visible &&
                  (sketchByEntityId[value.id]?.metadata['visible'] as bool? ??
                      true),
            },
          );
        }),
        ...constraints.map((value) {
          final referenceId = value.references.firstOrNull?.replaceFirst(
            RegExp(r':(start|end|point)$'),
            '',
          );
          return CadDocumentEntity(
            id: value.id,
            kind: CadDocumentEntityKind.constraint,
            data: {
              'name':
                  '${switch (value.type) {
                    SketchConstraintType.horizontal => '—',
                    SketchConstraintType.vertical => '|',
                    SketchConstraintType.coincident => '●',
                    SketchConstraintType.parallel => '∥',
                    SketchConstraintType.perpendicular => '⊥',
                    SketchConstraintType.concentric => '◎',
                    _ => '◇',
                  }} ${_constraintLabel(value.type)}',
              'group': 'Constraints',
              'parentSketchId': referenceId == null
                  ? activeSketch?.id
                  : sketchByEntityId[referenceId]?.id,
              'sceneVisible': value.visible,
              'symbol': switch (value.type) {
                SketchConstraintType.horizontal => '—',
                SketchConstraintType.vertical => '|',
                SketchConstraintType.coincident => '●',
                SketchConstraintType.parallel => '∥',
                SketchConstraintType.perpendicular => '⊥',
                SketchConstraintType.concentric => '◎',
                _ => '◇',
              },
              'constraint': value.toJson(),
            },
          );
        }),
        ...dimensions.map((value) {
          final referenceId = value.references.firstOrNull;
          final visual = _dimensionVisual(value, sketchByEntityId[referenceId]);
          return CadDocumentEntity(
            id: value.id,
            kind: CadDocumentEntityKind.constraint,
            data: {
              'name': '${value.type.name} ${value.value.toStringAsFixed(3)}',
              'group': 'Dimensions',
              'parentSketchId': referenceId == null
                  ? activeSketch?.id
                  : sketchByEntityId[referenceId]?.id,
              'sceneVisible': value.visible,
              'sceneKind': 'dimension',
              'sceneGeometry': visual.geometry,
              'dimension': value.toJson(),
            },
          );
        }),
      ],
    );
    await sketchApi?.persist();
    await editorApi?.persist();
    await constraintApi?.persist();
    _refreshSketchSurfacePreview();
    runtime.select(
      selectedConstraintIds.isNotEmpty
          ? selectedConstraintIds
          : _selectionWithDimensions(),
    );
  }

  CadSceneEntity _dimensionVisual(SketchDimension dimension, Sketch? sketch) {
    final entity = dimension.references.firstOrNull == null
        ? null
        : sketchApi?.entity(dimension.references.first);
    final localPoints = <SketchVector>[];
    if (entity is SketchLine) {
      localPoints.addAll([
        SketchVector.fromJson(entity.parameters['start']),
        SketchVector.fromJson(entity.parameters['end']),
      ]);
    } else if (entity is SketchCircle || entity is SketchArc) {
      final center = SketchVector.fromJson(entity!.parameters['center']);
      final radius = (entity.parameters['radius'] as num).toDouble();
      localPoints.addAll([center, SketchVector(center.x + radius, center.y)]);
    }
    final coordinates = sketch?.coordinates;
    final label = SketchVector(dimension.labelX, dimension.labelY);
    return CadSceneEntity(
      id: dimension.id,
      kind: CadSceneEntityKind.sketch,
      geometry: {
        'points': localPoints
            .map((point) => coordinates?.localToGlobal(point) ?? point)
            .map((point) => point.toJson())
            .toList(),
        'dimensionLabel': switch (dimension.type) {
          SketchDimensionType.radius =>
            'R ${dimension.value.toStringAsFixed(3)}',
          SketchDimensionType.diameter =>
            'Ø ${dimension.value.toStringAsFixed(3)}',
          SketchDimensionType.angular =>
            '${dimension.value.toStringAsFixed(2)}°',
          _ => dimension.value.toStringAsFixed(3),
        },
        'labelPosition': (coordinates?.localToGlobal(label) ?? label).toJson(),
        'displayColor': 'drivingDimension',
        'strokeWidth': 1.0,
      },
    );
  }

  void _refreshSketchSurfacePreview() {
    if (!surfacePreviewActive) return;
    final sketch = activeSketch;
    if (sketch == null || !sketchReadyForSurface) {
      runtime.hideTransient('surface-preview');
      runtime.write('sketch.surfacePreview.active', false);
      if (stage == SketchSurfaceStage.surfacePreview) {
        stage = SketchSurfaceStage.sketchActive;
      }
      return;
    }
    runtime.showTransient(
      _sketchSurfacePreviewBuilder.build(
        entities: sketchEntities,
        coordinates: sketch.coordinates,
      ),
    );
  }
}

class _SectionSplineFit {
  const _SectionSplineFit(
    this.controlPoints,
    this.sampledPoints,
    this.maximumError,
    this.meanError,
  );
  final List<SketchVector> controlPoints;
  final List<SketchVector> sampledPoints;
  final double maximumError;
  final double meanError;
}
