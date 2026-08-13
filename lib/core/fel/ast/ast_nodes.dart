import '../types/fel_type.dart';

sealed class FELNode {
  const FELNode(this.line);
  final int line;
  Map<String, dynamic> toJson();
}

sealed class StatementNode extends FELNode {
  const StatementNode(super.line);
}

sealed class ExpressionNode extends FELNode {
  const ExpressionNode(super.line);
}

class ProgramNode extends FELNode {
  const ProgramNode(this.statements) : super(1);
  final List<StatementNode> statements;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Program',
    'statements': statements.map((e) => e.toJson()).toList(),
  };
}

class LiteralNode extends ExpressionNode {
  const LiteralNode(super.line, this.value, this.valueType);
  final Object? value;
  final FELType valueType;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Literal',
    'line': line,
    'value': value,
    'valueType': valueType.name,
  };
}

class VariableNode extends ExpressionNode {
  const VariableNode(super.line, this.name);
  final String name;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Variable',
    'line': line,
    'name': name,
  };
}

class BinaryExpressionNode extends ExpressionNode {
  const BinaryExpressionNode(super.line, this.left, this.operator, this.right);
  final ExpressionNode left, right;
  final String operator;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Binary',
    'line': line,
    'operator': operator,
    'left': left.toJson(),
    'right': right.toJson(),
  };
}

class FunctionCallNode extends ExpressionNode {
  const FunctionCallNode(super.line, this.name, this.arguments);
  final String name;
  final List<ExpressionNode> arguments;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'FunctionCall',
    'line': line,
    'name': name,
    'arguments': arguments.map((e) => e.toJson()).toList(),
  };
}

class CommandNode extends StatementNode {
  const CommandNode(super.line, this.name, this.arguments);
  final String name;
  final List<ExpressionNode> arguments;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Command',
    'line': line,
    'name': name,
    'arguments': arguments.map((e) => e.toJson()).toList(),
  };
}

class VariableDeclarationNode extends StatementNode {
  const VariableDeclarationNode(
    super.line,
    this.kind,
    this.name,
    this.initializer,
  );
  final String kind, name;
  final ExpressionNode initializer;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'VariableDeclaration',
    'line': line,
    'kind': kind,
    'name': name,
    'initializer': initializer.toJson(),
  };
}

class PipelineNode extends StatementNode {
  const PipelineNode(super.line, this.commands);
  final List<CommandNode> commands;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Pipeline',
    'line': line,
    'commands': commands.map((e) => e.toJson()).toList(),
  };
}

class ConditionNode extends StatementNode {
  const ConditionNode(
    super.line,
    this.condition,
    this.thenBranch,
    this.elseBranch,
  );
  final ExpressionNode condition;
  final List<StatementNode> thenBranch, elseBranch;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Condition',
    'line': line,
    'condition': condition.toJson(),
    'then': thenBranch.map((e) => e.toJson()).toList(),
    'else': elseBranch.map((e) => e.toJson()).toList(),
  };
}

class LoopNode extends StatementNode {
  const LoopNode(super.line, this.kind, this.condition, this.body);
  final String kind;
  final ExpressionNode condition;
  final List<StatementNode> body;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Loop',
    'line': line,
    'kind': kind,
    'condition': condition.toJson(),
    'body': body.map((e) => e.toJson()).toList(),
  };
}

class ReturnNode extends StatementNode {
  const ReturnNode(super.line, this.value);
  final ExpressionNode? value;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Return',
    'line': line,
    'value': value?.toJson(),
  };
}

class BreakNode extends StatementNode {
  const BreakNode(super.line);
  @override
  Map<String, dynamic> toJson() => {'type': 'Break', 'line': line};
}

class ContinueNode extends StatementNode {
  const ContinueNode(super.line);
  @override
  Map<String, dynamic> toJson() => {'type': 'Continue', 'line': line};
}

class FunctionNode extends StatementNode {
  const FunctionNode(super.line, this.name, this.parameters, this.body);
  final String name;
  final List<String> parameters;
  final List<StatementNode> body;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Function',
    'line': line,
    'name': name,
    'parameters': parameters,
    'body': body.map((e) => e.toJson()).toList(),
  };
}

class RegionNode extends ExpressionNode {
  const RegionNode(super.line, this.reference);
  final String reference;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Region',
    'line': line,
    'reference': reference,
  };
}

class MeshNode extends ExpressionNode {
  const MeshNode(super.line, this.reference);
  final String reference;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'Mesh',
    'line': line,
    'reference': reference,
  };
}

class CADNode extends ExpressionNode {
  const CADNode(super.line, this.cadType, this.reference);
  final FELType cadType;
  final String reference;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'CAD',
    'line': line,
    'cadType': cadType.name,
    'reference': reference,
  };
}
