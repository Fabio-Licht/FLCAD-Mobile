import '../ast/ast_nodes.dart';
import '../commands/fel_command.dart';
import '../functions/fel_function_library.dart';
import '../types/fel_type.dart';

class FELDiagnostic {
  const FELDiagnostic(this.line, this.message, {this.isError = true});
  final int line;
  final String message;
  final bool isError;
}

class FELSemanticAnalyzer {
  FELSemanticAnalyzer(this.commands, this.functions);
  final FELCommandRegistry commands;
  final FELFunctionLibrary functions;
  List<FELDiagnostic> analyze(ProgramNode program) {
    final diagnostics = <FELDiagnostic>[], variables = <String, FELType>{};
    void expression(ExpressionNode node) {
      switch (node) {
        case VariableNode():
          if (!variables.containsKey(node.name)) {
            diagnostics.add(
              FELDiagnostic(node.line, 'Variável inexistente: ${node.name}'),
            );
          }
        case FunctionCallNode():
          if (functions.find(node.name) == null) {
            diagnostics.add(
              FELDiagnostic(node.line, 'Função inexistente: ${node.name}'),
            );
          }
          for (final a in node.arguments) {
            expression(a);
          }
        case BinaryExpressionNode():
          expression(node.left);
          expression(node.right);
        default:
          break;
      }
    }

    void statement(StatementNode node) {
      switch (node) {
        case VariableDeclarationNode():
          expression(node.initializer);
          if (node.kind == 'CONST' && variables.containsKey(node.name)) {
            diagnostics.add(
              FELDiagnostic(node.line, 'Constante já declarada: ${node.name}'),
            );
          }
          variables[node.name] = FELType.dynamicType;
        case CommandNode():
          if (commands.find(node.name) == null) {
            diagnostics.add(
              FELDiagnostic(node.line, 'Comando não registrado: ${node.name}'),
            );
          }
          for (final a in node.arguments) {
            expression(a);
          }
        case PipelineNode():
          for (final c in node.commands) {
            statement(c);
          }
        case ConditionNode():
          expression(node.condition);
          for (final s in node.thenBranch) {
            statement(s);
          }
          for (final s in node.elseBranch) {
            statement(s);
          }
        case LoopNode():
          expression(node.condition);
          for (final s in node.body) {
            statement(s);
          }
        case ReturnNode():
          if (node.value != null) expression(node.value!);
        default:
          break;
      }
    }

    for (final s in program.statements) {
      statement(s);
    }
    return diagnostics;
  }
}
