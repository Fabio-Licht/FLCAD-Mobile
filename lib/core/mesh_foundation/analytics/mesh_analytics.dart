class MeshAnalytics {
  int imports = 0,
      reloads = 0,
      repositoryUpdates = 0,
      diagnostics = 0,
      validations = 0,
      metadataGenerations = 0;
  int vertices = 0, triangles = 0, memoryBytes = 0;
  Duration importTime = Duration.zero;
  double get trianglesPerSecond => importTime.inMicroseconds == 0
      ? 0
      : triangles / (importTime.inMicroseconds / 1000000);
  Map<String, dynamic> toJson() => {
    'imports': imports,
    'reloads': reloads,
    'repositoryUpdates': repositoryUpdates,
    'diagnostics': diagnostics,
    'validations': validations,
    'metadataGenerations': metadataGenerations,
    'vertices': vertices,
    'triangles': triangles,
    'memoryBytes': memoryBytes,
    'importMicros': importTime.inMicroseconds,
    'trianglesPerSecond': trianglesPerSecond,
  };
}
