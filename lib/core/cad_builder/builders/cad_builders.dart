import '../../cad_kernel/models/kernel_models.dart';
import '../engine/cad_builder_engine.dart';
import '../models/cad_models.dart';

class VertexBuilder {
  const VertexBuilder(this.engine);
  final CadBuilderEngine engine;
  Future<CadBuildResult> point(double x, double y, double z) => engine.build(
    CADShapeType.vertex,
    'CREATE VERTEX',
    {'x': x, 'y': y, 'z': z},
    const [],
  );
}

class EdgeBuilder {
  const EdgeBuilder(this.engine);
  final CadBuilderEngine engine;
  Future<CadBuildResult> line(ShapeHandle start, ShapeHandle end) =>
      engine.build(
        CADShapeType.edge,
        'CREATE EDGE',
        {'kind': 'line', 'start': start, 'end': end},
        [start, end],
      );
  Future<CadBuildResult> arc(
    ShapeHandle start,
    ShapeHandle middle,
    ShapeHandle end,
  ) => engine.build(
    CADShapeType.edge,
    'CREATE EDGE',
    {'kind': 'arc', 'start': start, 'middle': middle, 'end': end},
    [start, middle, end],
  );
}

class WireBuilder {
  const WireBuilder(this.engine);
  final CadBuilderEngine engine;
  Future<CadBuildResult> build(
    List<ShapeHandle> edges, {
    required bool closed,
  }) {
    if (edges.isEmpty) throw ArgumentError('Wire requires edges');
    return engine.build(CADShapeType.wire, 'CREATE WIRE', {
      'edges': edges,
      'closed': closed,
    }, edges);
  }
}

class FaceBuilder {
  const FaceBuilder(this.engine);
  final CadBuilderEngine engine;
  Future<CadBuildResult> planar(
    ShapeHandle closedWire, {
    List<double>? planeOrigin,
    List<double>? planeNormal,
  }) {
    if (closedWire.type != CADShapeType.wire) {
      throw ArgumentError('Face requires a wire');
    }
    return engine.build(
      CADShapeType.face,
      'CREATE FACE',
      {
        'wire': closedWire,
        'planeOrigin': planeOrigin ?? const [0, 0, 0],
        'planeNormal': planeNormal ?? const [0, 0, 1],
      },
      [closedWire],
    );
  }
}

class ShellBuilder {
  const ShellBuilder(this.engine);
  final CadBuilderEngine engine;
  Future<CadBuildResult> sew(
    List<ShapeHandle> faces, {
    double tolerance = 0.001,
  }) {
    if (faces.isEmpty || faces.any((e) => e.type != CADShapeType.face)) {
      throw ArgumentError('Shell requires faces');
    }
    return engine.build(CADShapeType.shell, 'CREATE SHELL', {
      'faces': faces,
      'sewing': true,
      'tolerance': tolerance,
    }, faces);
  }
}

class SolidBuilder {
  const SolidBuilder(this.engine);
  final CadBuilderEngine engine;
  Future<CadBuildResult> fromClosedShell(ShapeHandle shell) => engine.build(
    CADShapeType.solid,
    'CREATE SOLID',
    {'shell': shell},
    [shell],
  );
}
