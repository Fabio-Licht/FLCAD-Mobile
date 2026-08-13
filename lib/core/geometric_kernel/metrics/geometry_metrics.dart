class GeometryMetrics {
  int operations = 0, failures = 0;
  Duration elapsed = Duration.zero;
  void record(Duration duration, {required bool success}) {
    operations++;
    elapsed += duration;
    if (!success) failures++;
  }
}
