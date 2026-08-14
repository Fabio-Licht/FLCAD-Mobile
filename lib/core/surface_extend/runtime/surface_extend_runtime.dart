class SurfaceExtendRuntime {
  SurfaceExtendRuntime._();
  static final instance = SurfaceExtendRuntime._();
  bool _initialized = false;
  bool get isInitialized => _initialized;
  Future<void> initialize() async => _initialized = true;
  Future<void> shutdown() async => _initialized = false;
}
