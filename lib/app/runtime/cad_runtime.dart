import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../core/cad_document/cad_document.dart';
import '../../core/cad_document/cad_document_repository.dart';
import '../../core/cad_kernel/api/geometry_kernel_api.dart';
import '../../core/cad_kernel/io/kernel_io_models.dart';
import '../../core/cad_kernel/models/kernel_models.dart';
import '../../core/cad_kernel/manager/kernel_manager.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';
import '../../core/geometric_kernel/linear_algebra/matrices.dart';
import '../../core/import_export/api/import_export_api.dart';
import '../cad_viewport/scene/cad_scene_graph.dart';
import '../commands/command_manager.dart';
import 'cad_document_scene_projection.dart';
import '../cad_viewport/rendering/kernel_display_mesh_pipeline.dart';
import '../engineering_bridge/selection/geometry_selection_manager.dart';
import 'world_coordinate_system.dart';

class CadRuntime extends ChangeNotifier {
  CadRuntime({
    required this.kernels,
    CadDocumentRepository repository = const CadDocumentRepository(),
  }) : _repository = repository,
       scene = CadSceneGraph() {
    projection = CadDocumentSceneProjection(scene);
    geometrySelection = GeometrySelectionManager(scene);
  }

  final CadDocumentRepository _repository;
  final KernelManager kernels;
  final CadSceneGraph scene;
  late final CadDocumentSceneProjection projection;
  late final GeometrySelectionManager geometrySelection;
  CadDocument? _document;
  Directory? _projectDirectory;
  ImportedCadDocument? _activeImport;
  KernelMeshGeometry? _activeMeshGeometry;
  KernelDisplayMeshPipeline? _displayMeshes;
  final List<CadDocument> _undo = [], _redo = [];
  CommandManager? _commands;
  Object? recognitionSession, sketchSession, surfaceSession;
  final Map<String, Object?> _state = {};

  CadDocument? get document => _document;
  ImportedCadDocument? get activeImport => _activeImport;
  KernelMeshGeometry? get activeMeshGeometry => _activeMeshGeometry;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  Set<String> get selection => geometrySelection.selectedIds;

  void attachCommands(CommandManager value) {
    final current = _commands;
    if (current != null && !identical(current, value)) {
      throw StateError('CadRuntime already owns a CommandManager.');
    }
    _commands = value;
  }

  Future<void> undoCommand() async {
    final commands = _commands;
    if (commands?.canUndo == true) {
      await commands!.undo();
    } else if (canUndo) {
      await undoDocument();
    } else {
      throw StateError('There is no command to undo.');
    }
  }

  Future<void> redoCommand() async {
    final commands = _commands;
    if (commands?.canRedo == true) {
      await commands!.redo();
    } else if (canRedo) {
      await redoDocument();
    } else {
      throw StateError('There is no command to redo.');
    }
  }

  Future<ShapeHandle?> officialExportShape() async {
    final shape = _document?.officialExportShape;
    if (shape == null) return null;
    final kernel = kernels.active;
    final directory = _projectDirectory;
    if (kernel is! PersistentGeometryKernelAPI || directory == null) {
      return shape;
    }
    final nativePath = path.join(
      directory.path,
      'NativeShapes',
      '${shape.persistentId}.brep',
    );
    if (!await File(nativePath).exists()) return shape;
    try {
      return await kernel.restoreShape(
        nativePath,
        persistentId: shape.persistentId,
      );
    } on StateError {
      return shape;
    }
  }

  T? read<T>(String key) => _state[key] as T?;
  T readOrCreate<T>(String key, T Function() create) =>
      (_state[key] ??= create()) as T;
  void write<T>(String key, T? value, {bool notify = false}) {
    if (value == null) {
      _state.remove(key);
    } else {
      _state[key] = value;
    }
    if (notify) notifyListeners();
  }

  Future<void> open(String projectId, Directory directory) async {
    _projectDirectory = directory;
    _document = await _repository.load(projectId, directory);
    final withWorldSystem = WorldCoordinateSystem.ensure(_document!);
    if (!identical(withWorldSystem, _document)) {
      _document = withWorldSystem;
      await _repository.save(_document!, directory);
    }
    final history = await _repository.loadHistory(directory);
    _displayMeshes = KernelDisplayMeshPipeline(
      kernel: kernels.active,
      projectId: projectId,
      projectDirectory: directory,
      scene: scene,
    );
    _restoreActiveImport();
    await projection.synchronize(_document!, displayMeshes: _displayMeshes);
    _undo
      ..clear()
      ..addAll(history.undo.where((item) => item.projectId == projectId));
    _redo
      ..clear()
      ..addAll(history.redo.where((item) => item.projectId == projectId));
    notifyListeners();
  }

  Future<void> close() async {
    await save();
    _document = null;
    _projectDirectory = null;
    _activeImport = null;
    _activeMeshGeometry = null;
    _displayMeshes = null;
    geometrySelection.clear();
    recognitionSession = sketchSession = surfaceSession = null;
    _state.clear();
    projection.clearTransient();
    await projection.synchronize(CadDocument.empty('closed'));
    notifyListeners();
  }

  Future<void> registerImport(
    ImportedCadDocument imported, {
    KernelMeshGeometry? geometry,
  }) async {
    projection.clearTransient();
    geometrySelection.clear();
    for (final key in const [
      'selection.pick',
      'selection.bridge',
      'session.context',
      'recognition.report',
      'recognition.filter',
      'recognition.decisions',
      'sections.meshBvh',
    ]) {
      _state.remove(key);
    }
    final current = _requireDocument();
    final replacedImports = current.entities.values
        .where((entity) => entity.kind == CadDocumentEntityKind.import)
        .map((entity) => entity.id)
        .where((id) => id != imported.id)
        .toList();
    final sceneGeometry = geometry == null
        ? <String, dynamic>{}
        : {
            'nodes': geometry.nodes,
            'triangles': geometry.triangles,
            'bounds': imported.mesh!.bounds.toJson(),
          };
    await mutate(
      command: 'import.${imported.format.name}',
      upsert: [
        CadDocumentEntity(
          id: imported.id,
          kind: CadDocumentEntityKind.import,
          shape: imported.shape,
          mesh: imported.mesh,
          data: {
            'sourcePath': imported.sourcePath,
            'registeredPath': imported.registeredPath,
            'format': imported.format.name,
            'validation': imported.validation,
            'sceneKind': imported.mesh == null ? 'solid' : 'mesh',
            'sceneGeometry': {
              ...sceneGeometry,
              if (imported.shape != null) 'handle': imported.shape!.toJson(),
            },
          },
        ),
      ],
      remove: replacedImports,
      officialExportShapeId: imported.shape == null
          ? current.officialExportShapeId
          : imported.id,
    );
    _activeImport = imported;
    _activeMeshGeometry = geometry;
    notifyListeners();
  }

  Future<void> mutate({
    required String command,
    Iterable<CadDocumentEntity> upsert = const [],
    Iterable<String> remove = const [],
    String? officialExportShapeId,
  }) async {
    final before = _requireDocument();
    _undo.add(before);
    _redo.clear();
    _document = before.mutate(
      command: command,
      upsert: upsert,
      remove: remove,
      officialExportShapeId: officialExportShapeId,
    );
    await projection.synchronize(_document!, displayMeshes: _displayMeshes);
    await save();
    notifyListeners();
  }

  Future<void> upsertEntity({
    required String command,
    required CadDocumentEntityKind kind,
    required CadSceneEntity entity,
    ShapeHandle? shape,
    KernelMeshHandle? mesh,
    Map<String, dynamic> data = const {},
    bool officialShape = false,
  }) => mutate(
    command: command,
    upsert: [
      CadDocumentEntity(
        id: entity.id,
        kind: kind,
        shape: shape,
        mesh: mesh,
        data: {
          ...data,
          'sceneKind': entity.kind.name,
          'sceneGeometry': entity.geometry,
          'sceneVisible': entity.visible,
          'sceneTransparent': entity.transparent,
        },
      ),
    ],
    officialExportShapeId: officialShape ? entity.id : null,
  );

  Future<void> removeEntity(String id, {required String command}) {
    final entity = _requireDocument().entities[id];
    if (entity != null && WorldCoordinateSystem.isProtected(entity)) {
      throw StateError('${entity.data['name']} is a protected system entity.');
    }
    return mutate(command: command, remove: [id]);
  }

  Future<void> setEntityVisibility(String id, bool visible) async {
    final entity =
        _requireDocument().entities[id] ??
        (throw StateError('Unknown document entity: $id'));
    await mutate(
      command: 'display.visibility',
      upsert: [
        CadDocumentEntity(
          id: entity.id,
          kind: entity.kind,
          shape: entity.shape,
          mesh: entity.mesh,
          data: {...entity.data, 'sceneVisible': visible},
        ),
      ],
    );
  }

  Future<void> applyAlignmentTransform(Matrix4 matrix) async {
    final current = _requireDocument();
    final transformed = <CadDocumentEntity>[];
    for (final entity in current.entities.values) {
      if (WorldCoordinateSystem.isProtected(entity)) continue;
      final data = _transformEntityData(entity.data, matrix);
      transformed.add(
        CadDocumentEntity(
          id: entity.id,
          kind: entity.kind,
          shape: entity.shape,
          mesh: _alignedMeshHandle(entity.mesh, data),
          data: data,
        ),
      );
    }
    await mutate(command: 'alignment.apply', upsert: transformed);
    _restoreActiveImport();
    notifyListeners();
  }

  KernelMeshHandle? _alignedMeshHandle(
    KernelMeshHandle? handle,
    Map<String, dynamic> data,
  ) {
    if (handle == null) return null;
    final scene = data['sceneGeometry'];
    final bounds = scene is Map ? scene['bounds'] : null;
    if (bounds is! Map || bounds['min'] is! List || bounds['max'] is! List) {
      return handle;
    }
    final minimum = (bounds['min'] as List).cast<num>();
    final maximum = (bounds['max'] as List).cast<num>();
    return KernelMeshHandle(
      persistentId: handle.persistentId,
      kernelId: handle.kernelId,
      fingerprint: handle.fingerprint,
      vertexCount: handle.vertexCount,
      triangleCount: handle.triangleCount,
      bounds: KernelBounds(
        minimum[0].toDouble(),
        minimum[1].toDouble(),
        minimum[2].toDouble(),
        maximum[0].toDouble(),
        maximum[1].toDouble(),
        maximum[2].toDouble(),
      ),
      hasNormals: handle.hasNormals,
      metadata: {...handle.metadata, 'aligned': true},
      degenerateTriangleCount: handle.degenerateTriangleCount,
    );
  }

  Map<String, dynamic> _transformEntityData(
    Map<String, dynamic> source,
    Matrix4 matrix,
  ) {
    final result = Map<String, dynamic>.from(source);
    final scene = source['sceneGeometry'];
    if (scene is Map) {
      result['sceneGeometry'] = _transformGeometry(
        Map<String, dynamic>.from(scene),
        matrix,
      );
    }
    final reference = source['reference'];
    if (reference is Map && reference['geometry'] is Map) {
      final copy = Map<String, dynamic>.from(reference);
      copy['geometry'] = _transformGeometry(
        Map<String, dynamic>.from(reference['geometry'] as Map),
        matrix,
      );
      result['reference'] = copy;
    }
    final sketch = source['sketch'];
    if (sketch is Map && sketch['coordinates'] is Map) {
      final copy = Map<String, dynamic>.from(sketch);
      copy['coordinates'] = _transformGeometry(
        Map<String, dynamic>.from(sketch['coordinates'] as Map),
        matrix,
      );
      result['sketch'] = copy;
    }
    result['alignmentMatrix'] = matrix.values;
    return result;
  }

  Map<String, dynamic> _transformGeometry(
    Map<String, dynamic> geometry,
    Matrix4 matrix,
  ) {
    final result = Map<String, dynamic>.from(geometry);
    Vector3 point(List value) => Vector3(
      (value[0] as num).toDouble(),
      (value[1] as num).toDouble(),
      (value[2] as num).toDouble(),
    );
    List<double> transformedPoint(List value) {
      final p = matrix.transformPoint(point(value));
      return [p.x, p.y, p.z];
    }

    List<double> transformedDirection(List value) {
      final origin = matrix.transformPoint(Vector3.zero);
      final p = matrix.transformPoint(point(value));
      final direction = (p - origin).normalized;
      return [direction.x, direction.y, direction.z];
    }

    final nodes = geometry['nodes'];
    if (nodes is List) {
      final values = nodes.cast<num>();
      final output = <double>[];
      for (var i = 0; i + 2 < values.length; i += 3) {
        output.addAll(transformedPoint(values.sublist(i, i + 3)));
      }
      result['nodes'] = output;
      if (output.isNotEmpty) {
        final xs = <double>[], ys = <double>[], zs = <double>[];
        for (var i = 0; i < output.length; i += 3) {
          xs.add(output[i]);
          ys.add(output[i + 1]);
          zs.add(output[i + 2]);
        }
        xs.sort();
        ys.sort();
        zs.sort();
        result['bounds'] = {
          'min': [xs.first, ys.first, zs.first],
          'max': [xs.last, ys.last, zs.last],
        };
      }
    }
    final points = geometry['points'];
    if (points is List) {
      result['points'] = [
        for (final value in points)
          if (value is List) transformedPoint(value),
      ];
    }
    for (final key in const ['origin', 'position']) {
      final value = geometry[key];
      if (value is List && value.length >= 3) {
        result[key] = transformedPoint(value);
      }
    }
    for (final key in const [
      'normal',
      'direction',
      'xDirection',
      'xAxis',
      'yAxis',
      'zAxis',
    ]) {
      final value = geometry[key];
      if (value is List && value.length >= 3) {
        result[key] = transformedDirection(value);
      }
    }
    return result;
  }

  void showTransient(CadSceneEntity entity) =>
      projection.upsertTransient(entity);

  Future<void> showTransientShape(
    CadSceneEntity entity,
    ShapeHandle shape,
  ) async {
    projection.upsertTransient(entity);
    final meshes = _displayMeshes;
    if (meshes == null) return;
    await meshes.upsert(entityId: entity.id, shape: shape);
    final rendered = scene.find(entity.id);
    if (rendered != null) projection.upsertTransient(rendered);
  }

  void hideTransient(String id) => projection.removeTransient(id);

  Future<void> undoDocument() async {
    if (_undo.isEmpty) return;
    _redo.add(_requireDocument());
    _document = _undo.removeLast();
    _restoreActiveImport();
    await projection.synchronize(_document!, displayMeshes: _displayMeshes);
    await save();
    notifyListeners();
  }

  Future<void> redoDocument() async {
    if (_redo.isEmpty) return;
    _undo.add(_requireDocument());
    _document = _redo.removeLast();
    _restoreActiveImport();
    await projection.synchronize(_document!, displayMeshes: _displayMeshes);
    await save();
    notifyListeners();
  }

  Future<void> save() async {
    final document = _document, directory = _projectDirectory;
    if (document != null && directory != null) {
      await _repository.save(document, directory);
      await _repository.saveHistory(directory, undo: _undo, redo: _redo);
    }
  }

  void select(Set<String> ids) {
    geometrySelection.replace(ids);
    notifyListeners();
  }

  CadDocument _requireDocument() =>
      _document ?? (throw StateError('CadRuntime has no active document.'));

  void _restoreActiveImport() {
    _activeImport = null;
    _activeMeshGeometry = null;
    final imports = _document!.entities.values
        .where((entity) => entity.kind == CadDocumentEntityKind.import)
        .toList();
    if (imports.isEmpty) return;
    final value = imports.last, data = value.data;
    _activeImport = ImportedCadDocument(
      id: value.id,
      projectId: _document!.projectId,
      sourcePath: data['sourcePath'] as String,
      registeredPath: data['registeredPath'] as String,
      format: CadImportFormat.values.byName(data['format'] as String),
      validation: (data['validation'] as List? ?? const []).cast<String>(),
      shape: value.shape,
      mesh: value.mesh,
    );
    final sceneGeometry = data['sceneGeometry'];
    if (sceneGeometry is Map && sceneGeometry['nodes'] is List) {
      _activeMeshGeometry = KernelMeshGeometry(
        nodes: (sceneGeometry['nodes'] as List)
            .cast<num>()
            .map((value) => value.toDouble())
            .toList(),
        triangles: (sceneGeometry['triangles'] as List).cast<int>(),
      );
    }
  }

  @override
  void dispose() {
    geometrySelection.dispose();
    scene.dispose();
    super.dispose();
  }
}
