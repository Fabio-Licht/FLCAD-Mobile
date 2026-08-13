import '../io/kernel_io_models.dart';
import '../models/kernel_models.dart';

/// Boundary of the native OCCT host. Native tokens are private to this module.
abstract interface class OpenCascadeNativeBridge {
  Future<void> initialize();
  Future<void> shutdown();
  Future<String> version();
  Future<Map<String, dynamic>> diagnostics();
  Future<OpenCascadeNativeShape> createShape(
    String operation,
    Map<String, dynamic> parameters,
    CADShapeType expectedType,
  );
  Future<OpenCascadeNativeShape> importShape(
    String path,
    KernelExchangeFormat format, {
    required KernelCancellationToken cancellation,
    void Function(KernelProgress progress)? onProgress,
  });
  Future<void> exportShape(
    String nativeToken,
    String path,
    KernelExchangeFormat format, {
    required KernelCancellationToken cancellation,
    void Function(KernelProgress progress)? onProgress,
  });
  Future<List<GeometryDiagnostic>> validate(String nativeToken);
  Future<List<HealingProposal>> proposeHealing(String nativeToken);
  Future<OpenCascadeNativeShape> sew(
    List<String> nativeTokens,
    double tolerance,
  );
  Future<KernelMeshData> mesh(
    String nativeToken,
    String outputPath,
    double deflection,
  );
}

class OpenCascadeNativeShape {
  const OpenCascadeNativeShape({
    required this.token,
    required this.type,
    required this.fingerprint,
    this.metadata = const {},
  });
  final String token, fingerprint;
  final CADShapeType type;
  final Map<String, dynamic> metadata;
}

class KernelMeshData {
  const KernelMeshData(this.vertexCount, this.triangleCount, this.payloadPath);
  final int vertexCount, triangleCount;
  final String payloadPath;
}

class UnavailableOpenCascadeBridge implements OpenCascadeNativeBridge {
  const UnavailableOpenCascadeBridge([
    this.reason = 'OpenCascade native host is not installed',
  ]);
  final String reason;
  Never _fail() => throw StateError(reason);
  @override
  Future<void> initialize() async => _fail();
  @override
  Future<void> shutdown() async {}
  @override
  Future<String> version() async => _fail();
  @override
  Future<Map<String, dynamic>> diagnostics() async => {
    'available': false,
    'reason': reason,
  };
  @override
  Future<OpenCascadeNativeShape> createShape(
    String operation,
    Map<String, dynamic> parameters,
    CADShapeType expectedType,
  ) async => _fail();
  @override
  Future<OpenCascadeNativeShape> importShape(
    String path,
    KernelExchangeFormat format, {
    required KernelCancellationToken cancellation,
    void Function(KernelProgress progress)? onProgress,
  }) async => _fail();
  @override
  Future<void> exportShape(
    String nativeToken,
    String path,
    KernelExchangeFormat format, {
    required KernelCancellationToken cancellation,
    void Function(KernelProgress progress)? onProgress,
  }) async => _fail();
  @override
  Future<List<GeometryDiagnostic>> validate(String nativeToken) async =>
      _fail();
  @override
  Future<List<HealingProposal>> proposeHealing(String nativeToken) async =>
      _fail();
  @override
  Future<OpenCascadeNativeShape> sew(
    List<String> nativeTokens,
    double tolerance,
  ) async => _fail();
  @override
  Future<KernelMeshData> mesh(
    String nativeToken,
    String outputPath,
    double deflection,
  ) async => _fail();
}
