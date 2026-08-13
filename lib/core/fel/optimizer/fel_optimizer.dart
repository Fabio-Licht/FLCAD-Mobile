import '../ast/ast_nodes.dart';

class FELOptimizer {
  const FELOptimizer();
  ProgramNode optimize(ProgramNode program) {
    final output = <StatementNode>[];
    for (final statement in program.statements) {
      if (statement is PipelineNode) {
        final commands = <CommandNode>[];
        for (final command in statement.commands) {
          if (commands.isNotEmpty && _redundant(commands.last, command)) {
            continue;
          }
          commands.add(command);
        }
        output.add(PipelineNode(statement.line, commands));
      } else if (statement is CommandNode &&
          output.isNotEmpty &&
          output.last is CommandNode &&
          _redundant(output.last as CommandNode, statement)) {
        continue;
      } else {
        output.add(statement);
      }
    }
    return ProgramNode(output);
  }

  bool _redundant(CommandNode a, CommandNode b) =>
      a.name == b.name && const {'SAVE PROJECT'}.contains(a.name);
}
