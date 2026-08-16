// ignore_for_file: curly_braces_in_flow_control_structures

class EngineeringBridgeRuntime {
  bool _initialized = false;
  bool get initialized => _initialized;
  Future<void> initialize() async => _initialized = true;
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (!_initialized)
      throw StateError('Engineering Bridge runtime is not initialized.');
    return operation();
  }

  Future<void> shutdown() async => _initialized = false;
}
