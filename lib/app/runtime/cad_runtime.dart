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
    final initialized = _ensureProfessionalCollections(
      WorldCoordinateSystem.ensure(_document!),
    );
    if (!identical(initialized, _document)) {
      _document = initialized;
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
            'collectionId': 'collection:original',
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
    final changed = upsert.toList(growable: false);
    final removed = remove.toList(growable: false);
    final before = _requireDocument();
    _undo.add(before);
    _redo.clear();
    _document = before.mutate(
      command: command,
      upsert: changed,
      remove: removed,
      officialExportShapeId: officialExportShapeId,
    );
    await projection.synchronizeChanges(
      _document!,
      upsert: changed,
      remove: removed,
      displayMeshes: _displayMeshes,
    );
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
  }) async {
    if (shape != null) await _persistNativeShape(shape);
    await mutate(
      command: command,
      upsert: [
        CadDocumentEntity(
          id: entity.id,
          kind: kind,
          shape: shape,
          mesh: mesh,
          data: {
            ...data,
            'collectionId': data['collectionId'] ?? _defaultCollectionFor(kind),
            'sceneKind': entity.kind.name,
            'sceneGeometry': entity.geometry,
            'sceneVisible': entity.visible,
            'sceneTransparent': entity.transparent,
          },
        ),
      ],
      officialExportShapeId: officialShape ? entity.id : null,
    );
  }

  /// Resolves a persisted kernel shape into the active native kernel session.
  Future<ShapeHandle> loadShape(ShapeHandle handle) => _loadedShape(handle);

  Future<void> persistShape(ShapeHandle handle) => _persistNativeShape(handle);

  String _defaultCollectionFor(CadDocumentEntityKind kind) => switch (kind) {
    CadDocumentEntityKind.reference => 'collection:references',
    CadDocumentEntityKind.curve => 'collection:modified',
    CadDocumentEntityKind.vertex ||
    CadDocumentEntityKind.edge ||
    CadDocumentEntityKind.wire ||
    CadDocumentEntityKind.face ||
    CadDocumentEntityKind.shell ||
    CadDocumentEntityKind.solid => 'collection:modified',
    CadDocumentEntityKind.import => 'collection:original',
    CadDocumentEntityKind.collection => 'collection:modified',
    _ => 'collection:modified',
  };

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
    final sceneEntity = scene.find(id);
    if (sceneEntity != null && sceneEntity.visible != visible) {
      scene.upsert(sceneEntity.copyWith(visible: visible));
    }
    try {
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
    } catch (_) {
      if (sceneEntity != null) scene.upsert(sceneEntity);
      rethrow;
    }
  }

  Future<void> applyAlignmentTransform(Matrix4 matrix) async {
    final ids = _requireDocument().entities.values
        .where(
          (entity) =>
              entity.kind != CadDocumentEntityKind.collection &&
              !WorldCoordinateSystem.isProtected(entity),
        )
        .map((entity) => entity.id)
        .toSet();
    await applyEntityTransform(ids, matrix, command: 'alignment.apply');
  }

  /// Applies the official document transform to a selected set of entities.
  ///
  /// Geometry stays owned by [CadDocument]; the scene graph receives only the
  /// incremental projection emitted by [mutate]. Kernel-backed BRep entities
  /// are transformed through the active kernel's native shape-transform
  /// contract, preventing display-only transforms from diverging from the
  /// official export shape.
  Future<void> applyEntityTransform(
    Set<String> entityIds,
    Matrix4 matrix, {
    String command = 'transform.apply',
    bool createCopy = false,
  }) async {
    if (entityIds.isEmpty) {
      throw StateError('Select at least one entity to transform.');
    }
    final current = _requireDocument();
    final transformed = <CadDocumentEntity>[];
    String? exportEntityId;
    String? workingCollectionId;
    if (createCopy) {
      workingCollectionId = _nextWorkingCollectionId(current);
      transformed.add(
        _collectionEntity(
          workingCollectionId,
          'Working Copy ${workingCollectionId.split('-').last}',
          color: 'blue',
          active: true,
        ),
      );
      for (final collection in current.entities.values.where(
        (item) => item.kind == CadDocumentEntityKind.collection,
      )) {
        if (collection.data['active'] == true) {
          transformed.add(
            CadDocumentEntity(
              id: collection.id,
              kind: collection.kind,
              data: {...collection.data, 'active': false},
            ),
          );
        }
      }
    }
    for (final id in entityIds) {
      final entity = current.entities[id];
      if (entity == null) throw StateError('Unknown document entity: $id');
      if (WorldCoordinateSystem.isProtected(entity)) {
        throw StateError(
          '${entity.data['name']} is a protected system entity.',
        );
      }
      final collection = current.entities[entity.data['collectionId']];
      if (collection?.data['locked'] == true) {
        throw StateError(
          '${collection!.data['name']} is locked. Unlock it before transforming entities.',
        );
      }
      final data = _transformEntityData(entity.data, matrix);
      ShapeHandle? shape = entity.shape;
      if (shape != null) {
        final kernel = kernels.active;
        if (kernel is! ShapeTransformGeometryKernelAPI) {
          throw StateError(
            '${kernel.descriptor.name} does not implement ShapeTransformGeometryKernelAPI.',
          );
        }
        shape = await kernel.transformShape(
          await _loadedShape(shape),
          matrix.values,
          projectId: current.projectId,
          copyGeometry: true,
        );
        await _persistNativeShape(shape);
        data['sceneGeometry'] = {
          ...Map<String, dynamic>.from(
            data['sceneGeometry'] as Map? ?? const {},
          ),
          'handle': shape.toJson(),
        };
      }
      final outputId = createCopy
          ? 'copy:${shape?.persistentId ?? '${entity.id}:${DateTime.now().microsecondsSinceEpoch}'}'
          : entity.id;
      if (createCopy) {
        data['name'] = '${entity.data['name'] ?? entity.id} (Working Copy)';
        data['sourceEntityId'] = entity.id;
        data['collectionId'] = workingCollectionId;
      } else {
        data['collectionId'] = 'collection:modified';
      }
      transformed.add(
        CadDocumentEntity(
          id: outputId,
          kind: entity.kind,
          shape: shape,
          mesh: _alignedMeshHandle(entity.mesh, data),
          data: data,
        ),
      );
      if (shape != null) exportEntityId = outputId;
    }
    await mutate(
      command: createCopy ? '$command.copy' : command,
      upsert: transformed,
      officialExportShapeId: exportEntityId,
    );
    _restoreActiveImport();
    notifyListeners();
  }

  Future<ShapeHandle> _loadedShape(ShapeHandle handle) async {
    final kernel = kernels.active;
    final directory = _projectDirectory;
    if (kernel is! PersistentGeometryKernelAPI || directory == null) {
      return handle;
    }
    final payload = path.join(
      directory.path,
      'NativeShapes',
      '${handle.persistentId}.brep',
    );
    if (!await File(payload).exists()) return handle;
    try {
      return await kernel.restoreShape(
        payload,
        persistentId: handle.persistentId,
      );
    } on StateError {
      return handle;
    }
  }

  Future<void> _persistNativeShape(ShapeHandle handle) async {
    final kernel = kernels.active;
    final directory = _projectDirectory;
    if (kernel is! PersistentGeometryKernelAPI || directory == null) return;
    final folder = Directory(path.join(directory.path, 'NativeShapes'));
    await folder.create(recursive: true);
    await kernel.persistShape(
      handle,
      path.join(folder.path, '${handle.persistentId}.brep'),
    );
  }

  String _nextWorkingCollectionId(CadDocument document) {
    var index = 1;
    while (document.entities.containsKey(
      'collection:working-copy-${index.toString().padLeft(3, '0')}',
    )) {
      index++;
    }
    return 'collection:working-copy-${index.toString().padLeft(3, '0')}';
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
    final localCoordinates = source['localCoordinateSystem'];
    if (localCoordinates is Map) {
      result['localCoordinateSystem'] = _transformGeometry(
        Map<String, dynamic>.from(localCoordinates),
        matrix,
      );
    }
    final section = source['section'];
    if (section is Map) {
      result['section'] = _transformGeometry(
        Map<String, dynamic>.from(section),
        matrix,
      );
    }
    final previous = source['transformMatrix'];
    final cumulative = previous is List && previous.length == 16
        ? matrix *
              Matrix4(previous.cast<num>().map((v) => v.toDouble()).toList())
        : matrix;
    result['transformMatrix'] = cumulative.values;
    result['alignmentMatrix'] = cumulative.values;
    return result;
  }

  Map<String, dynamic> transformedSceneGeometry(
    CadDocumentEntity entity,
    Matrix4 matrix,
  ) {
    final geometry = entity.data['sceneGeometry'];
    if (geometry is! Map) {
      throw StateError('${entity.id} has no projectable geometry.');
    }
    return _transformGeometry(Map<String, dynamic>.from(geometry), matrix);
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
    final segments = geometry['segments'];
    if (segments is List) {
      result['segments'] = [
        for (final raw in segments)
          if (raw is List && raw.length >= 2)
            [
              transformedPoint(raw[0] as List),
              transformedPoint(raw[1] as List),
            ],
      ];
    }
    for (final key in const ['origin', 'position', 'center']) {
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

  Future<ShapeHandle> previewNativeShapeTransform(
    ShapeHandle source,
    Matrix4 matrix,
  ) async {
    final kernel = kernels.active;
    if (kernel is! ShapeTransformGeometryKernelAPI) {
      throw StateError(
        '${kernel.descriptor.name} does not support native shape transforms.',
      );
    }
    return kernel.transformShape(
      await _loadedShape(source),
      matrix.values,
      projectId: _requireDocument().projectId,
      copyGeometry: true,
    );
  }

  void hideTransient(String id) => projection.removeTransient(id);

  CadDocument _ensureProfessionalCollections(CadDocument document) {
    const definitions = [
      ('collection:original', 'Original', 'gray'),
      ('collection:working-copy', 'Working Copy', 'blue'),
      ('collection:modified', 'Modified', 'orange'),
      ('collection:inspection', 'Inspection', 'purple'),
      ('collection:references', 'References', 'teal'),
      ('collection:recycle-bin', 'Recycle Bin', 'red'),
    ];
    final missing = <CadDocumentEntity>[];
    for (final definition in definitions) {
      if (!document.entities.containsKey(definition.$1)) {
        missing.add(
          _collectionEntity(
            definition.$1,
            definition.$2,
            color: definition.$3,
            active: definition.$1 == 'collection:original',
          ),
        );
      }
    }
    for (final entity in document.entities.values) {
      if (entity.kind == CadDocumentEntityKind.collection ||
          entity.data['collectionId'] != null) {
        continue;
      }
      missing.add(
        CadDocumentEntity(
          id: entity.id,
          kind: entity.kind,
          shape: entity.shape,
          mesh: entity.mesh,
          data: {
            ...entity.data,
            'collectionId': _defaultCollectionFor(entity.kind),
          },
        ),
      );
    }
    if (missing.isEmpty) return document;
    return document.mutate(command: 'collections.initialize', upsert: missing);
  }

  CadDocumentEntity _collectionEntity(
    String id,
    String name, {
    required String color,
    bool active = false,
  }) => CadDocumentEntity(
    id: id,
    kind: CadDocumentEntityKind.collection,
    data: {
      'name': name,
      'color': color,
      'visible': true,
      'locked': id == 'collection:recycle-bin',
      'active': active,
      'systemCollection':
          id.startsWith('collection:') &&
          !id.startsWith('collection:working-copy-'),
    },
  );

  Future<void> updateCollection(
    String id, {
    String? name,
    bool? visible,
    bool? locked,
    bool? active,
  }) async {
    final document = _requireDocument();
    final collection = document.entities[id];
    if (collection?.kind != CadDocumentEntityKind.collection) {
      throw StateError('Unknown Collection: $id');
    }
    final collectionData = Map<String, dynamic>.from(collection!.data);
    if (name != null) collectionData['name'] = name;
    if (visible != null) collectionData['visible'] = visible;
    if (locked != null) collectionData['locked'] = locked;
    if (active != null) collectionData['active'] = active;
    final updates = <CadDocumentEntity>[
      CadDocumentEntity(id: id, kind: collection.kind, data: collectionData),
    ];
    if (active == true) {
      updates.addAll(
        document.entities.values
            .where(
              (item) =>
                  item.kind == CadDocumentEntityKind.collection &&
                  item.id != id &&
                  item.data['active'] == true,
            )
            .map(
              (item) => CadDocumentEntity(
                id: item.id,
                kind: item.kind,
                data: {...item.data, 'active': false},
              ),
            ),
      );
    }
    if (visible != null) {
      updates.addAll(
        document.entities.values
            .where((item) => item.data['collectionId'] == id)
            .map(
              (item) => CadDocumentEntity(
                id: item.id,
                kind: item.kind,
                shape: item.shape,
                mesh: item.mesh,
                data: {...item.data, 'sceneVisible': visible},
              ),
            ),
      );
    }
    await mutate(command: 'collection.update', upsert: updates);
  }

  Future<void> duplicateCollection(String id) async {
    final document = _requireDocument();
    final source = document.entities[id];
    if (source?.kind != CadDocumentEntityKind.collection) {
      throw StateError('Unknown Collection: $id');
    }
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final copyId = 'collection:copy-$stamp';
    final copies = <CadDocumentEntity>[
      _collectionEntity(
        copyId,
        '${source!.data['name']} Copy',
        color: source.data['color'] as String? ?? 'blue',
      ),
    ];
    for (final entity in document.entities.values.where(
      (item) => item.data['collectionId'] == id && item.data['deleted'] != true,
    )) {
      ShapeHandle? shape = entity.shape;
      if (shape != null) {
        final kernel = kernels.active;
        if (kernel is! ShapeTransformGeometryKernelAPI) {
          throw StateError(
            '${kernel.descriptor.name} cannot duplicate native shapes.',
          );
        }
        shape = await kernel.transformShape(
          await _loadedShape(shape),
          Matrix4.identity().values,
          projectId: document.projectId,
          copyGeometry: true,
        );
        await _persistNativeShape(shape);
      }
      final entityId = 'copy:${shape?.persistentId ?? '${entity.id}:$stamp'}';
      copies.add(
        CadDocumentEntity(
          id: entityId,
          kind: entity.kind,
          shape: shape,
          mesh: entity.mesh,
          data: {
            ...entity.data,
            'name': '${entity.data['name'] ?? entity.id} Copy',
            'sourceEntityId': entity.id,
            'collectionId': copyId,
            if (shape != null)
              'sceneGeometry': {
                ...Map<String, dynamic>.from(
                  entity.data['sceneGeometry'] as Map? ?? const {},
                ),
                'handle': shape.toJson(),
              },
          },
        ),
      );
    }
    await mutate(command: 'collection.duplicate', upsert: copies);
  }

  List<CadDocumentEntity> dependencyImpact(String entityId) {
    final document = _requireDocument();
    final impacted = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      final sources = {entityId, ...impacted};
      for (final entity in document.entities.values) {
        if (entity.id == entityId || impacted.contains(entity.id)) continue;
        if (sources.any((source) => _containsReference(entity.data, source))) {
          changed = impacted.add(entity.id) || changed;
        }
      }
    }
    return impacted.map((id) => document.entities[id]!).toList();
  }

  bool _containsReference(Object? value, String id) {
    if (value == id) return true;
    if (value is Map) {
      return value.values.any((item) => _containsReference(item, id));
    }
    if (value is Iterable) {
      return value.any((item) => _containsReference(item, id));
    }
    return false;
  }

  Future<void> moveToRecycleBin(
    String entityId, {
    required bool includeDependencies,
  }) async {
    final document = _requireDocument();
    final target =
        document.entities[entityId] ??
        (throw StateError('Unknown document entity: $entityId'));
    if (WorldCoordinateSystem.isProtected(target)) {
      throw StateError('World Coordinate System entities cannot be deleted.');
    }
    final entities = <CadDocumentEntity>[
      target,
      if (includeDependencies) ...dependencyImpact(entityId),
    ];
    await mutate(
      command: 'recycle.delete',
      upsert: [
        for (final entity in entities)
          CadDocumentEntity(
            id: entity.id,
            kind: entity.kind,
            shape: entity.shape,
            mesh: entity.mesh,
            data: {
              ...entity.data,
              'deleted': true,
              'deletedAt': DateTime.now().toUtc().toIso8601String(),
              'previousCollectionId': entity.data['collectionId'],
              'collectionId': 'collection:recycle-bin',
              'sceneVisible': false,
            },
          ),
      ],
    );
  }

  Future<void> restoreFromRecycleBin(String entityId) async {
    final entity =
        _requireDocument().entities[entityId] ??
        (throw StateError('Unknown document entity: $entityId'));
    if (entity.data['deleted'] != true) {
      throw StateError('${entity.data['name'] ?? entity.id} is not deleted.');
    }
    final data = Map<String, dynamic>.from(entity.data)
      ..remove('deleted')
      ..remove('deletedAt');
    data['collectionId'] =
        data.remove('previousCollectionId') ?? 'collection:original';
    data['sceneVisible'] = true;
    await mutate(
      command: 'recycle.restore',
      upsert: [
        CadDocumentEntity(
          id: entity.id,
          kind: entity.kind,
          shape: entity.shape,
          mesh: entity.mesh,
          data: data,
        ),
      ],
    );
  }

  Future<void> permanentlyDelete(String entityId) async {
    final entity =
        _requireDocument().entities[entityId] ??
        (throw StateError('Unknown document entity: $entityId'));
    if (entity.data['deleted'] != true) {
      throw StateError('Only Recycle Bin entities can be permanently deleted.');
    }
    await removeEntity(entityId, command: 'recycle.purge');
  }

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
