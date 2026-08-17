import '../analytics/kernel_analytics.dart';
import '../api/geometry_kernel_api.dart';
import '../ids/persistent_id_service.dart';
import '../io/kernel_io_models.dart';
import '../models/kernel_models.dart';
import '../runtime/kernel_runtime.dart';
import 'open_cascade_bridge.dart';
import 'open_cascade_ffi.dart';

class OpenCascadeKernelAdapter
    implements
        InterchangeGeometryKernelAPI,
        PersistentGeometryKernelAPI,
        ShapeTransformGeometryKernelAPI,
        MeshGeometryKernelAPI,
        SurfaceTopologyKernelAPI,
        SurfaceQualityKernelAPI,
        ReversibleSurfaceOperationKernelAPI {
  OpenCascadeKernelAdapter({
    OpenCascadeNativeBridge? bridge,
    OpenCascadeNativeBridge Function()? bridgeFactory,
    KernelAnalytics? analytics,
    PersistentIdService? ids,
  }) : _bridge = bridge,
       _bridgeFactory = bridgeFactory ?? OpenCascadeFFI.loadOrUnavailable,
       _ids = ids ?? const PersistentIdService(),
       runtime = KernelRuntime(analytics: analytics ?? KernelAnalytics());
  OpenCascadeNativeBridge? _bridge;
  final OpenCascadeNativeBridge Function() _bridgeFactory;
  OpenCascadeNativeBridge get _nativeBridge => _bridge ??= _bridgeFactory();
  final PersistentIdService _ids;
  final KernelRuntime runtime;
  final Map<String, String> _nativeTokens = {};
  final Map<String, String> _nativeMeshTokens = {};
  final Map<String, bool> _surfaceHistory = {};
  String _version = 'uninitialized';
  Set<KernelCapability> _capabilities = {};
  bool _initialized = false;
  Future<void>? _initialization;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await _nativeBridge.initialize();
    _version = await _nativeBridge.version();
    _capabilities = _mapCapabilities(await _nativeBridge.capabilities());
    _initialized = true;
  }

  @override
  KernelDescriptor get descriptor => KernelDescriptor(
    id: 'opencascade',
    name: 'OpenCascade',
    version: _version,
    vendor: 'Open CASCADE Technology',
    capabilities: KernelCapabilities(_capabilities),
  );

  Set<KernelCapability> _mapCapabilities(Set<String> native) {
    final normalized = native.map((e) => e.toLowerCase()).toSet();
    return {
      if (normalized.contains('step')) KernelCapability.step,
      if (normalized.contains('iges')) KernelCapability.iges,
      if (normalized.contains('brep')) KernelCapability.brep,
      if (normalized.contains('boolean')) KernelCapability.boolean,
      if (normalized.contains('healing')) KernelCapability.healing,
      if (normalized.contains('meshing')) KernelCapability.meshing,
      if (normalized.contains('loft')) KernelCapability.loft,
      if (normalized.contains('sweep')) KernelCapability.sweep,
      if (normalized.contains('offset')) KernelCapability.offset,
      if (normalized.contains('surface')) ...{
        KernelCapability.planeSurface,
        KernelCapability.cylinderSurface,
        KernelCapability.coneSurface,
        KernelCapability.sphereSurface,
        KernelCapability.torusSurface,
      },
    };
  }

  @override
  Future<KernelHealth> healthCheck() async {
    try {
      if (!_initialized) await initialize();
      final data = await _nativeBridge.diagnostics();
      return KernelHealth(
        data['healthy'] == false
            ? KernelHealthStatus.degraded
            : KernelHealthStatus.healthy,
        data['message'] as String? ?? 'OpenCascade $_version ready',
        DateTime.now(),
      );
    } catch (error) {
      return KernelHealth(
        KernelHealthStatus.unavailable,
        error.toString(),
        DateTime.now(),
      );
    }
  }

  ShapeHandle _handle(OpenCascadeNativeShape shape, String projectId) {
    final id = _ids.create(projectId, shape.type.name);
    _nativeTokens[id] = shape.token;
    return ShapeHandle.reference(
      persistentId: id,
      kernelId: descriptor.id,
      type: shape.type,
      fingerprint: shape.fingerprint,
      metadata: shape.metadata,
    );
  }

  String _resolve(ShapeHandle handle) {
    if (handle.kernelId != descriptor.id) {
      throw ArgumentError(
        'Shape belongs to ${handle.kernelId}, not OpenCascade',
      );
    }
    return _nativeTokens[handle.persistentId] ??
        (throw StateError(
          'Native shape is not loaded for ${handle.persistentId}',
        ));
  }

  @override
  Future<ShapeHandle> importFile(
    String path,
    KernelExchangeFormat format, {
    required String projectId,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => runtime.run(
    'occ-import-${format.name}',
    () async {
      await initialize();
      return _handle(
        await _nativeBridge.importShape(
          path,
          format,
          cancellation: cancellation,
          onProgress: onProgress,
        ),
        projectId,
      );
    },
    entityCount: 1,
    runInIsolate: false,
  );

  @override
  Future<void> persistShape(ShapeHandle handle, String payloadPath) async {
    await initialize();
    await _nativeBridge.exportShape(
      _resolve(handle),
      payloadPath,
      KernelExchangeFormat.brep,
      cancellation: const NoKernelCancellation(),
    );
  }

  @override
  Future<ShapeHandle> restoreShape(
    String payloadPath, {
    required String persistentId,
  }) async {
    await initialize();
    final native = await _nativeBridge.importShape(
      payloadPath,
      KernelExchangeFormat.brep,
      cancellation: const NoKernelCancellation(),
    );
    _nativeTokens[persistentId] = native.token;
    return ShapeHandle.reference(
      persistentId: persistentId,
      kernelId: descriptor.id,
      type: native.type,
      fingerprint: native.fingerprint,
      metadata: {...native.metadata, 'restoredFrom': payloadPath},
    );
  }

  @override
  Future<ShapeHandle> transformShape(
    ShapeHandle source,
    List<double> matrix, {
    required String projectId,
    bool copyGeometry = true,
  }) => runtime.run(
    'occ-transform-shape',
    () async {
      await initialize();
      if (matrix.length != 16 || matrix.any((value) => !value.isFinite)) {
        throw ArgumentError('Shape transform requires a finite 4x4 matrix.');
      }
      final native = await _nativeBridge.transformShape(
        _resolve(source),
        matrix,
        copyGeometry: copyGeometry,
      );
      return _handle(native, projectId);
    },
    entityCount: 1,
    runInIsolate: false,
  );

  @override
  Future<KernelMeshHandle> importStl(
    String path, {
    required String projectId,
    KernelImportFormat format = KernelImportFormat.autoDetect,
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => runtime.run(
    'occ-import-stl',
    () async {
      await initialize();
      final bridge = _nativeBridge;
      if (bridge is! OpenCascadeMeshNativeBridge) {
        throw StateError('OpenCascade bridge does not support STL mesh import');
      }
      final meshBridge = bridge as OpenCascadeMeshNativeBridge;
      final native = await meshBridge.importStl(
        path,
        format,
        cancellation: cancellation,
        onProgress: onProgress,
      );
      final id = _ids.create(projectId, 'mesh');
      _nativeMeshTokens[id] = native.token;
      return KernelMeshHandle(
        persistentId: id,
        kernelId: descriptor.id,
        fingerprint: native.fingerprint,
        vertexCount: native.vertexCount,
        triangleCount: native.triangleCount,
        bounds: native.bounds,
        hasNormals: native.hasNormals,
        degenerateTriangleCount: native.degenerateTriangleCount,
        metadata: {
          'source': path,
          'format': format.name,
          'backend': 'OpenCascade',
          'nativeType': 'Poly_Triangulation',
        },
      );
    },
    entityCount: 1,
    runInIsolate: false,
  );

  @override
  Future<void> closeMesh(KernelMeshHandle handle) async {
    if (handle.kernelId != descriptor.id) {
      throw ArgumentError(
        'Mesh belongs to ${handle.kernelId}, not OpenCascade',
      );
    }
    final token =
        _nativeMeshTokens.remove(handle.persistentId) ??
        (throw StateError(
          'Native mesh is not loaded for ${handle.persistentId}',
        ));
    final bridge = _nativeBridge;
    if (bridge is! OpenCascadeMeshNativeBridge) {
      throw StateError('OpenCascade bridge does not support mesh lifetime');
    }
    await (bridge as OpenCascadeMeshNativeBridge).destroyMesh(token);
  }

  @override
  Future<KernelMeshGeometry> inspectMesh(KernelMeshHandle handle) async {
    if (handle.kernelId != descriptor.id) {
      throw ArgumentError(
        'Mesh belongs to ${handle.kernelId}, not OpenCascade',
      );
    }
    final token =
        _nativeMeshTokens[handle.persistentId] ??
        (throw StateError(
          'Native mesh is not loaded for ${handle.persistentId}',
        ));
    final bridge = _nativeBridge;
    if (bridge is! OpenCascadeMeshNativeBridge) {
      throw StateError('OpenCascade bridge does not support mesh inspection');
    }
    return (bridge as OpenCascadeMeshNativeBridge).inspectMesh(
      token,
      vertexCount: handle.vertexCount,
      triangleCount: handle.triangleCount,
    );
  }

  @override
  Future<void> exportFile(
    ShapeHandle handle,
    String path,
    KernelExchangeFormat format, {
    KernelCancellationToken cancellation = const NoKernelCancellation(),
    void Function(KernelProgress progress)? onProgress,
  }) => runtime.run('occ-export-${format.name}', () async {
    await initialize();
    await _nativeBridge.exportShape(
      _resolve(handle),
      path,
      format,
      cancellation: cancellation,
      onProgress: onProgress,
    );
  }, runInIsolate: false);
  @override
  Future<List<GeometryDiagnostic>> diagnose(ShapeHandle handle) =>
      runtime.run('occ-validate', () async {
        await initialize();
        return _nativeBridge.validate(_resolve(handle));
      }, runInIsolate: false);
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      (await diagnose(
        handle,
      )).map((e) => '${e.severity}:${e.code}:${e.message}').toList();
  @override
  Future<List<HealingProposal>> proposeHealing(ShapeHandle handle) =>
      runtime.run('occ-healing-proposals', () async {
        await initialize();
        return _nativeBridge.proposeHealing(_resolve(handle));
      }, runInIsolate: false);
  @override
  Future<ShapeHandle> sew(
    List<ShapeHandle> faces, {
    required String projectId,
    required double tolerance,
  }) => runtime.run(
    'occ-sewing',
    () async {
      await initialize();
      return _handle(
        await _nativeBridge.sew(faces.map(_resolve).toList(), tolerance),
        projectId,
      );
    },
    entityCount: 1,
    runInIsolate: false,
  );
  @override
  Future<KernelMeshResult> mesh(
    ShapeHandle handle, {
    required String outputPath,
    required double deflection,
  }) => runtime.run('occ-meshing', () async {
    await initialize();
    final result = await _nativeBridge.mesh(
      _resolve(handle),
      outputPath,
      deflection,
    );
    return KernelMeshResult(
      source: handle,
      vertexCount: result.vertexCount,
      triangleCount: result.triangleCount,
      payloadPath: result.payloadPath,
    );
  }, runInIsolate: false);
  @override
  Future<ShapeHandle> create(
    String operation,
    Map<String, dynamic> parameters, {
    required String persistentId,
    required CADShapeType expectedType,
    required KernelTransaction transaction,
  }) => runtime.run(
    'occ-${operation.toLowerCase().replaceAll(' ', '-')}',
    () async {
      await initialize();
      final nativeParameters = Map<String, dynamic>.from(parameters);
      for (final entry in parameters.entries) {
        final value = entry.value;
        if (value is ShapeHandle) nativeParameters[entry.key] = _resolve(value);
        if (value is List<ShapeHandle>) {
          nativeParameters[entry.key] = value.map(_resolve).toList();
        }
      }
      final professional = _professionalOperation(operation);
      final bridge = _nativeBridge;
      final shape =
          professional != null && bridge is OpenCascadeSurfaceNativeBridge
          ? await (bridge as OpenCascadeSurfaceNativeBridge)
                .executeSurfaceOperation(
                  professional,
                  sourceToken: nativeParameters['source'] as String?,
                  referenceTokens: _stringList(nativeParameters['references']),
                  values: _surfaceValues(professional, nativeParameters),
                )
          : await bridge.createShape(operation, nativeParameters, expectedType);
      _nativeTokens[persistentId] = shape.token;
      return ShapeHandle.reference(
        persistentId: persistentId,
        kernelId: descriptor.id,
        type: shape.type,
        fingerprint: shape.fingerprint,
        metadata: shape.metadata,
      );
    },
    entityCount: 1,
    runInIsolate: false,
  );
  @override
  Future<void> begin(KernelTransaction transaction) async {}
  @override
  Future<void> commit(KernelTransaction transaction) async {}
  @override
  Future<void> rollback(KernelTransaction transaction) async {}
  Future<void> destroy(ShapeHandle handle) async {
    final token = _resolve(handle);
    await initialize();
    await _nativeBridge.destroyShape(token);
    _nativeTokens.remove(handle.persistentId);
  }

  @override
  Future<KernelSurfaceTopology> inspectSurfaceTopology(
    ShapeHandle surface,
  ) async {
    await initialize();
    final value = await _nativeBridge.inspectSurfaceTopology(_resolve(surface));
    return KernelSurfaceTopology(
      boundaries: [
        for (final item in (value['boundaries'] as List))
          KernelBoundaryData(
            index: item['index'] as int,
            length: (item['length'] as num).toDouble(),
            closed: item['closed'] as bool,
          ),
      ],
      loops: [
        for (final item in (value['loops'] as List))
          KernelLoopData(
            index: item['index'] as int,
            closed: item['closed'] as bool,
            boundaryIndices: (item['boundaries'] as List).cast<int>(),
          ),
      ],
    );
  }

  @override
  Future<KernelSurfaceIntersection> intersectSurfaces(
    ShapeHandle first,
    ShapeHandle second, {
    required String projectId,
  }) async {
    await initialize();
    final value = await _nativeBridge.intersectSurfaces(
      _resolve(first),
      _resolve(second),
    );
    ShapeHandle? handle;
    final token = value['token'] as String?;
    if (token != null) {
      final id = _ids.create(projectId, 'intersection');
      _nativeTokens[id] = token;
      handle = ShapeHandle.reference(
        persistentId: id,
        kernelId: descriptor.id,
        type: CADShapeType.compound,
        fingerprint: 'intersection:${first.fingerprint}:${second.fingerprint}',
      );
    }
    return KernelSurfaceIntersection(
      edgeCount: value['edgeCount'] as int,
      length: (value['length'] as num).toDouble(),
      handle: handle,
    );
  }

  @override
  Future<Map<String, dynamic>> inspectSurfaceQuality(
    ShapeHandle surface, {
    required List<double> draftDirection,
    int samples = 100,
  }) async {
    await initialize();
    return _nativeBridge.inspectSurfaceQuality(
      _resolve(surface),
      draftDirection: draftDirection,
      samples: samples,
    );
  }

  @override
  Future<KernelSurfaceOperationResult> executeSurfaceOperation(
    ShapeHandle surface,
    String operation,
    Map<String, dynamic> parameters, {
    required String projectId,
  }) async {
    await initialize();
    final nativeOperation = _professionalOperation(operation);
    if (nativeOperation == null) {
      return KernelSurfaceOperationResult(
        supported: false,
        diagnostic: _limitation(operation),
      );
    }
    final bridge = _nativeBridge;
    if (bridge is! OpenCascadeSurfaceNativeBridge) {
      return const KernelSurfaceOperationResult(
        supported: false,
        diagnostic:
            'FFI bridge does not implement OpenCascadeSurfaceNativeBridge',
      );
    }
    final references = <String>[];
    final rawReferences = parameters['references'];
    if (rawReferences is List<ShapeHandle>) {
      references.addAll(rawReferences.map(_resolve));
    } else if (rawReferences is List) {
      for (final value in rawReferences) {
        if (value is ShapeHandle) references.add(_resolve(value));
      }
    }
    final native = await (bridge as OpenCascadeSurfaceNativeBridge)
        .executeSurfaceOperation(
          nativeOperation,
          sourceToken: _resolve(surface),
          referenceTokens: references,
          values: _surfaceValues(nativeOperation, parameters),
        );
    final result = _handle(native, projectId);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final undo = 'occ-undo:$stamp:${result.persistentId}';
    final redo = 'occ-redo:$stamp:${result.persistentId}';
    _surfaceHistory[undo] = true;
    _surfaceHistory[redo] = false;
    return KernelSurfaceOperationResult(
      supported: true,
      diagnostic:
          'OpenCascade $nativeOperation completed with ${native.metadata['operator']}',
      result: result,
      undoToken: undo,
      redoToken: redo,
    );
  }

  @override
  Future<void> rollbackSurfaceOperation(String undoToken) async {
    if (_surfaceHistory[undoToken] != true) {
      throw StateError(
        'Unknown or already consumed OpenCascade undo token: $undoToken',
      );
    }
    _surfaceHistory[undoToken] = false;
    final redo = undoToken.replaceFirst('occ-undo:', 'occ-redo:');
    _surfaceHistory[redo] = true;
  }

  @override
  Future<void> redoSurfaceOperation(String redoToken) async {
    if (_surfaceHistory[redoToken] != true) {
      throw StateError(
        'Unknown or already consumed OpenCascade redo token: $redoToken',
      );
    }
    _surfaceHistory[redoToken] = false;
    final undo = redoToken.replaceFirst('occ-redo:', 'occ-undo:');
    _surfaceHistory[undo] = true;
  }

  @override
  Future<void> unload() async {
    if (_bridge != null) await _nativeBridge.shutdown();
    _nativeTokens.clear();
    _nativeMeshTokens.clear();
    _surfaceHistory.clear();
    _initialized = false;
    _initialization = null;
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  static List<double> _surfaceValues(
    String operation,
    Map<String, dynamic> parameters,
  ) {
    double number(String key, double fallback) =>
        (parameters[key] as num?)?.toDouble() ?? fallback;
    return switch (operation) {
      'LOFT' => [number('tolerance', 1e-6)],
      'FILL' || 'PATCH' || 'BLEND' || 'MATCH' => [
        number('degree', 3),
        number('pointsOnCurve', 15),
        number('iterations', 2),
        number('tolerance2d', 1e-4),
        number('tolerance3d', 1e-4),
        number('angularTolerance', 1e-3),
        number('curvatureTolerance', .1),
        number('maximumDegree', 8),
      ],
      'OFFSET' => [number('distance', 0), number('tolerance', 1e-4)],
      'EXTEND' => [
        number('length', 0),
        number('continuity', 1),
        parameters['inU'] == true ? 1 : 0,
        parameters['after'] == false ? 0 : 1,
        number('tolerance', 1e-6),
      ],
      'REDUCE' => [
        number('tolerance3d', 1e-4),
        number('tolerance2d', 1e-4),
        number('maximumDegree', 8),
        number('maximumSegments', 100),
      ],
      'TRIM' => [
        number('uMin', 0),
        number('uMax', 1),
        number('vMin', 0),
        number('vMax', 1),
        number('tolerance', 1e-6),
      ],
      'JOIN' || 'SEW' => [number('tolerance', 1e-4)],
      _ => const [],
    };
  }

  static String? _professionalOperation(String value) {
    final normalized = value.toUpperCase().replaceAll('_', ' ');
    for (final operation in const [
      'LOFT',
      'SWEEP',
      'FILL',
      'PATCH',
      'BLEND',
      'NURBS',
      'EXTEND',
      'REDUCE',
      'OFFSET',
      'TRIM',
      'SPLIT',
      'JOIN',
      'SEW',
      'HEAL',
      'MATCH',
      'FAIR',
      'BOUNDARY',
      'MORPH',
    ]) {
      if (normalized.contains(operation)) return operation;
    }
    return null;
  }

  static String _limitation(String operation) {
    final normalized = operation.toUpperCase();
    if (normalized.contains('FAIR')) {
      return 'OCCT 8.0.1 provides FairCurve for curves, but no general surface fairing operator';
    }
    if (normalized.contains('MORPH')) {
      return 'OCCT 8.0.1 has no general-purpose surface morph operator';
    }
    return 'No GeometryKernelAPI to OCCT 8.0.1 mapping is registered for $operation';
  }
}
