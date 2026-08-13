import '../commands/region_command.dart';
import '../models/geometry.dart';
import '../pipeline/region_pipeline.dart';
import '../selection/triangle_selection.dart';

class RegionScript {
  const RegionScript(this.name, this.commands);
  final String name;
  final List<RegionCommand> commands;
  Map<String, dynamic> toJson() => {
    'name': name,
    'commands': commands.map((e) => e.toJson()).toList(),
  };
}

class RegionScriptEngine {
  TriangleSelection execute(
    RegionScript script,
    MeshTopology mesh,
    TriangleSelection input,
  ) => RegionPipeline(script.commands).run(mesh, input);
}
