import '../builders/cad_builders.dart';
import '../engine/cad_builder_engine.dart';

class CadBuilderApi {
  CadBuilderApi(this.engine)
    : vertex = VertexBuilder(engine),
      edge = EdgeBuilder(engine),
      wire = WireBuilder(engine),
      face = FaceBuilder(engine),
      shell = ShellBuilder(engine),
      solid = SolidBuilder(engine);
  final CadBuilderEngine engine;
  final VertexBuilder vertex;
  final EdgeBuilder edge;
  final WireBuilder wire;
  final FaceBuilder face;
  final ShellBuilder shell;
  final SolidBuilder solid;
}
