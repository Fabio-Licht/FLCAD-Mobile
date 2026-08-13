import '../commands/region_command.dart';
import '../models/geometry.dart';
import '../selection/triangle_selection.dart';

class RegionPipeline {
  const RegionPipeline(this.commands);
  final List<RegionCommand> commands;
  TriangleSelection run(MeshTopology mesh, TriangleSelection input) {
    var output = input;
    for (final command in commands) {
      output = command.execute(mesh, output);
    }
    return output;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'commands': commands.map((e) => e.toJson()).toList(),
  };
}
