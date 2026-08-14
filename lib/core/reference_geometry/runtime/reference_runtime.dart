class ReferenceRuntime {
  bool _initialized = false;
  bool get initialized => _initialized;
  Future<void> initialize() async => _initialized = true;
  Future<void> shutdown() async => _initialized = false;
}
