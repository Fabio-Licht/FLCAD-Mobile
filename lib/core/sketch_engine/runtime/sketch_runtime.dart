class SketchRuntime {
  bool _running = false;
  DateTime? startedAt;
  bool get isRunning => _running;
  void initialize() {
    if (_running) return;
    _running = true;
    startedAt = DateTime.now().toUtc();
  }

  void shutdown() {
    _running = false;
  }
}
