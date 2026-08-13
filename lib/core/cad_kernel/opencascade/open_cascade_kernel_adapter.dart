import '../analytics/kernel_analytics.dart';
import '../api/geometry_kernel_api.dart';
import '../ids/persistent_id_service.dart';
import '../io/kernel_io_models.dart';
import '../models/kernel_models.dart';
import '../runtime/kernel_runtime.dart';
import 'open_cascade_bridge.dart';

class OpenCascadeKernelAdapter implements InterchangeGeometryKernelAPI {
  OpenCascadeKernelAdapter({
    required OpenCascadeNativeBridge bridge,
    KernelAnalytics? analytics,
    PersistentIdService? ids,
  }) : _bridge = bridge,
       _ids = ids ?? const PersistentIdService(),
       runtime = KernelRuntime(analytics: analytics ?? KernelAnalytics());
  final OpenCascadeNativeBridge _bridge;
  final PersistentIdService _ids;
  final KernelRuntime runtime;
  final Map<String, String> _nativeTokens = {};
  String _version = 'uninitialized';
  bool _initialized = false;

  Future<void> initialize() async {
    await _bridge.initialize();
    _version = await _bridge.version();
    _initialized = true;
  }

  @override
  KernelDescriptor get descriptor => KernelDescriptor(
    id: 'opencascade',
    name: 'OpenCascade',
    version: _version,
    vendor: 'Open CASCADE Technology',
    capabilities: const KernelCapabilities({
      KernelCapability.step,
      KernelCapability.iges,
      KernelCapability.brep,
      KernelCapability.healing,
      KernelCapability.meshing,
      KernelCapability.boolean,
      KernelCapability.extrude,
      KernelCapability.revolve,
      KernelCapability.sweep,
      KernelCapability.loft,
      KernelCapability.offset,
      KernelCapability.shell,
      KernelCapability.draft,
      KernelCapability.mirror,
      KernelCapability.linearPattern,
      KernelCapability.circularPattern,
    }),
  );
  @override
  Future<KernelHealth> healthCheck() async {
    try {
      if (!_initialized) await initialize();
      final data = await _bridge.diagnostics();
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
    () async => _handle(
      await _bridge.importShape(
        path,
        format,
        cancellation: cancellation,
        onProgress: onProgress,
      ),
      projectId,
    ),
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
  }) => runtime.run(
    'occ-export-${format.name}',
    () => _bridge.exportShape(
      _resolve(handle),
      path,
      format,
      cancellation: cancellation,
      onProgress: onProgress,
    ),
    runInIsolate: false,
  );
  @override
  Future<List<GeometryDiagnostic>> diagnose(ShapeHandle handle) => runtime.run(
    'occ-validate',
    () => _bridge.validate(_resolve(handle)),
    runInIsolate: false,
  );
  @override
  Future<List<String>> validate(ShapeHandle handle, Set<String> checks) async =>
      (await diagnose(
        handle,
      )).map((e) => '${e.severity}:${e.code}:${e.message}').toList();
  @override
  Future<List<HealingProposal>> proposeHealing(ShapeHandle handle) =>
      runtime.run(
        'occ-healing-proposals',
        () => _bridge.proposeHealing(_resolve(handle)),
        runInIsolate: false,
      );
  @override
  Future<ShapeHandle> sew(
    List<ShapeHandle> faces, {
    required String projectId,
    required double tolerance,
  }) => runtime.run(
    'occ-sewing',
    () async => _handle(
      await _bridge.sew(faces.map(_resolve).toList(), tolerance),
      projectId,
    ),
    entityCount: 1,
    runInIsolate: false,
  );
  @override
  Future<KernelMeshResult> mesh(
    ShapeHandle handle, {
    required String outputPath,
    required double deflection,
  }) => runtime.run('occ-meshing', () async {
    final result = await _bridge.mesh(_resolve(handle), outputPath, deflection);
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
      final nativeParameters = Map<String, dynamic>.from(parameters);
      for (final entry in parameters.entries) {
        final value = entry.value;
        if (value is ShapeHandle) nativeParameters[entry.key] = _resolve(value);
        if (value is List<ShapeHandle>) {
          nativeParameters[entry.key] = value.map(_resolve).toList();
        }
      }
      final shape = await _bridge.createShape(
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
  @override
  Future<void> unload() async {
    await _bridge.shutdown();
    _nativeTokens.clear();
    _initialized = false;
  }
}
