class ConstraintRuntime {
  bool _initialized = false;
  bool get isInitialized => _initialized;
  void initialize() => _initialized = true;
  void shutdown() => _initialized = false;
}
