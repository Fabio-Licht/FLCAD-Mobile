class EngineeringMemorySnapshot {
  const EngineeringMemorySnapshot({
    required this.timestamp,
    required this.rssBytes,
    required this.heapBytes,
    this.labels = const {},
  });
  final DateTime timestamp;
  final int rssBytes, heapBytes;
  final Map<String, String> labels;
}

class EngineeringFrameTiming {
  const EngineeringFrameTiming(this.timestamp, this.build, this.raster);
  final DateTime timestamp;
  final Duration build, raster;
}

abstract interface class EngineeringPerformanceProbe {
  Future<EngineeringMemorySnapshot> memorySnapshot(Map<String, String> labels);
  Stream<EngineeringFrameTiming> get frameTimings;
}

class EngineeringStressScenario<T> {
  const EngineeringStressScenario({
    required this.name,
    required this.iterations,
    required this.operation,
    this.profileModeOnly = true,
  });
  final String name;
  final int iterations;
  final Future<T> Function(int iteration) operation;
  final bool profileModeOnly;
}
