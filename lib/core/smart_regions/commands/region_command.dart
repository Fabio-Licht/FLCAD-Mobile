import '../engine/smart_border_engine.dart';
import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

abstract interface class RegionCommand {
  String get id;
  TriangleSelection execute(MeshTopology mesh, TriangleSelection input);
  Map<String, dynamic> toJson();
}

class ExpandCommand implements RegionCommand {
  const ExpandCommand(this.rings);
  final int rings;
  @override
  String get id => 'expand';
  @override
  TriangleSelection execute(MeshTopology mesh, TriangleSelection input) =>
      const SmartBorderEngine().expand(mesh, input, rings: rings);
  @override
  Map<String, dynamic> toJson() => {'id': id, 'rings': rings};
}

class ShrinkCommand implements RegionCommand {
  const ShrinkCommand(this.rings);
  final int rings;
  @override
  String get id => 'shrink';
  @override
  TriangleSelection execute(MeshTopology mesh, TriangleSelection input) =>
      const SmartBorderEngine().shrink(mesh, input, rings: rings);
  @override
  Map<String, dynamic> toJson() => {'id': id, 'rings': rings};
}

class SmoothCommand implements RegionCommand {
  const SmoothCommand(this.iterations);
  final int iterations;
  @override
  String get id => 'smooth';
  @override
  TriangleSelection execute(MeshTopology mesh, TriangleSelection input) =>
      const SmartBorderEngine().smooth(mesh, input, iterations: iterations);
  @override
  Map<String, dynamic> toJson() => {'id': id, 'iterations': iterations};
}
