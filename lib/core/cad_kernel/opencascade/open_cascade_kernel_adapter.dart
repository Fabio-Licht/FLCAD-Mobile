import '../analytics/kernel_analytics.dart';
import '../api/geometry_kernel_api.dart';
import '../ids/persistent_id_service.dart';
import '../io/kernel_io_models.dart';
import '../models/kernel_models.dart';
import '../runtime/kernel_runtime.dart';
import 'open_cascade_bridge.dart';
import 'open_cascade_ffi.dart';

class OpenCascadeKernelAdapter implements InterchangeGeometryKernelAPI {
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
      if (normalized.contains('surface')) ...{
        KernelCapability.planeSurface,
        KernelCapability.cylinderSurface,
        KernelCapability.coneSurface,
        KernelCapability.sphereSurface,
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
      final shape = await _nativeBridge.createShape(
        operation,
        nativeParameters,
        expectedType,
      );
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
  Future<void> unload() async {
    if (_bridge != null) await _nativeBridge.shutdown();
    _nativeTokens.clear();
    _initialized = false;
    _initialization = null;
  }
}
