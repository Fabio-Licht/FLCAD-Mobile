import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

abstract interface class GPUSelectionEngine {
  Future<TriangleSelection> select(MeshTopology mesh, String expression);
}

abstract interface class GPUFilteringEngine {
  Future<TriangleSelection> filter(MeshTopology mesh, TriangleSelection input);
}

abstract interface class GPURenderingEngine {
  Future<void> render(MeshTopology mesh, TriangleSelection input);
}

abstract interface class GPUAnalyticsEngine {
  Future<Map<String, dynamic>> analyze(
    MeshTopology mesh,
    TriangleSelection input,
  );
}

class CPUSelectionFallback {
  TriangleSelection selectAll(MeshTopology mesh) =>
      TriangleSelection(Iterable.generate(mesh.triangles.length));
}
