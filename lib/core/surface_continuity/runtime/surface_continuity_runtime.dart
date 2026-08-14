class SurfaceContinuityRuntime {
  SurfaceContinuityRuntime._();
  static final instance = SurfaceContinuityRuntime._();
  bool _initialized = false;
  bool get isInitialized => _initialized;
  Future<void> initialize() async => _initialized = true;
  Future<void> shutdown() async => _initialized = false;
}
