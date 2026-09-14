/// Transient STL presentation budget, mirrored by StlDisplayBudget in C++.
abstract final class StlDisplayLod {
  static const maxTriangles = 250000;
  static const maxVertices = 125000;
  static const maxNativeWorkingBytes = 128 * 1024 * 1024;
  static const maxJsonBytes = 24 * 1024 * 1024;

  static bool simplified(Map<String, dynamic> geometry) =>
      geometry['presentationLod'] is Map;

  /// Length checks run before normals reconstruction, serialization or copies.
  static void preflight(Map<String, dynamic> geometry) {
    if (geometry['stlPresentation'] != true && !simplified(geometry)) return;
    final nodes = geometry['nodes'];
    final faces = geometry['triangles'];
    if (nodes is! List ||
        faces is! List ||
        nodes.isEmpty ||
        faces.isEmpty ||
        nodes.length % 3 != 0 ||
        faces.length % 3 != 0 ||
        nodes.length > maxVertices * 3 ||
        faces.length > maxTriangles * 3) {
      throw const FormatException('STL presentation budget exceeded');
    }
    if (simplified(geometry)) {
      final lod = geometry['presentationLod'] as Map;
      final normals = geometry['normals'];
      if (lod['version'] != 1 ||
          lod['measurementSafe'] != false ||
          lod['method'] != 'spatial-clustering-v1' ||
          lod['originalTriangles'] is! int ||
          lod['originalVertices'] is! int ||
          (lod['originalTriangles'] as int) < faces.length ~/ 3 ||
          (lod['originalVertices'] as int) < nodes.length ~/ 3 ||
          lod['displayTriangles'] != faces.length ~/ 3 ||
          lod['displayVertices'] != nodes.length ~/ 3 ||
          normals is! List ||
          normals.length != nodes.length) {
        throw const FormatException('Invalid STL presentation LOD');
      }
    }
  }
}
