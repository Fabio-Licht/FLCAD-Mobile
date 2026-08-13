import '../ast/ast_nodes.dart';
import '../lexer/token.dart';
import '../types/fel_type.dart';

class FELParserException implements Exception {
  const FELParserException(this.message, this.token);
  final String message;
  final FELToken token;
  @override
  String toString() =>
      'FELParserException ${token.line}:${token.column} $message';
}

class FELParser {
  FELParser(this.tokens);
  final List<FELToken> tokens;
  var _current = 0;
  ProgramNode parse() {
    final statements = <StatementNode>[];
    _separators();
    while (!_check(FELTokenType.eof)) {
      statements.add(_statement());
      _separators();
    }
    return ProgramNode(statements);
  }

  StatementNode _statement() {
    if (_keyword('LET') || _keyword('CONST') || _keyword('VAR')) {
      return _variable(_previous);
    }
    if (_keyword('IF')) return _condition(_previous.line);
    if (_keyword('WHILE')) return _loop('WHILE', _previous.line);
    if (_keyword('RETURN')) {
      return ReturnNode(
        _previous.line,
        _atEndOfStatement() ? null : _expression(),
      );
    }
    if (_keyword('BREAK')) return BreakNode(_previous.line);
    if (_keyword('CONTINUE')) return ContinueNode(_previous.line);
    final first = _command();
    if (_match(FELTokenType.arrow)) {
      final commands = <CommandNode>[first];
      do {
        _separators();
        commands.add(_command());
      } while (_match(FELTokenType.arrow));
      return PipelineNode(first.line, commands);
    }
    return first;
  }

  VariableDeclarationNode _variable(FELToken kind) {
    final name = _consume(FELTokenType.identifier, 'Nome de variável esperado');
    _consume(FELTokenType.equals, '= esperado');
    return VariableDeclarationNode(
      kind.line,
      kind.lexeme,
      name.lexeme,
      _expression(),
    );
  }

  ConditionNode _condition(int line) {
    final condition = _expression();
    final thenBranch = _block();
    List<StatementNode> elseBranch = const [];
    _separators();
    if (_keyword('ELSE')) elseBranch = _block();
    return ConditionNode(line, condition, thenBranch, elseBranch);
  }

  LoopNode _loop(String kind, int line) =>
      LoopNode(line, kind, _expression(), _block());
  List<StatementNode> _block() {
    _consume(FELTokenType.leftBrace, '{ esperado');
    final body = <StatementNode>[];
    _separators();
    while (!_check(FELTokenType.rightBrace) && !_check(FELTokenType.eof)) {
      body.add(_statement());
      _separators();
    }
    _consume(FELTokenType.rightBrace, '} esperado');
    return body;
  }

  CommandNode _command() {
    final start = _consumeAny([
      FELTokenType.identifier,
      FELTokenType.keyword,
    ], 'Comando esperado');
    final parts = <String>[start.lexeme];
    while (_check(FELTokenType.identifier) ||
        (_check(FELTokenType.keyword) && !_control(_peek.lexeme))) {
      parts.add(_advance.lexeme);
    }
    final args = <ExpressionNode>[];
    while (!_atEndOfStatement() &&
        !_check(FELTokenType.arrow) &&
        !_check(FELTokenType.rightBrace)) {
      args.add(_expression());
      if (!_match(FELTokenType.comma) &&
          (_check(FELTokenType.newline) ||
              _check(FELTokenType.semicolon) ||
              _check(FELTokenType.arrow))) {
        break;
      }
    }
    return CommandNode(start.line, parts.join(' '), args);
  }

  ExpressionNode _expression() => _equality();
  ExpressionNode _equality() {
    var expr = _comparison();
    while (_matchAny([FELTokenType.equalEqual, FELTokenType.bangEqual])) {
      final op = _previous.lexeme;
      expr = BinaryExpressionNode(_previous.line, expr, op, _comparison());
    }
    return expr;
  }

  ExpressionNode _comparison() {
    var expr = _term();
    while (_matchAny([
      FELTokenType.greater,
      FELTokenType.greaterEqual,
      FELTokenType.less,
      FELTokenType.lessEqual,
    ])) {
      final op = _previous.lexeme;
      expr = BinaryExpressionNode(_previous.line, expr, op, _term());
    }
    return expr;
  }

  ExpressionNode _term() {
    var expr = _factor();
    while (_matchAny([FELTokenType.plus, FELTokenType.minus])) {
      final op = _previous.lexeme;
      expr = BinaryExpressionNode(_previous.line, expr, op, _factor());
    }
    return expr;
  }

  ExpressionNode _factor() {
    var expr = _primary();
    while (_matchAny([FELTokenType.star, FELTokenType.slash])) {
      final op = _previous.lexeme;
      expr = BinaryExpressionNode(_previous.line, expr, op, _primary());
    }
    return expr;
  }

  ExpressionNode _primary() {
    if (_match(FELTokenType.number)) {
      return LiteralNode(_previous.line, _previous.literal, FELType.number);
    }
    if (_match(FELTokenType.string)) {
      return LiteralNode(_previous.line, _previous.literal, FELType.string);
    }
    if (_keyword('TRUE')) {
      return LiteralNode(_previous.line, true, FELType.boolean);
    }
    if (_keyword('FALSE')) {
      return LiteralNode(_previous.line, false, FELType.boolean);
    }
    if (_match(FELTokenType.identifier)) {
      final name = _previous;
      if (_match(FELTokenType.leftParen)) {
        final args = <ExpressionNode>[];
        if (!_check(FELTokenType.rightParen)) {
          do {
            args.add(_expression());
          } while (_match(FELTokenType.comma));
        }
        _consume(FELTokenType.rightParen, ') esperado');
        return FunctionCallNode(name.line, name.lexeme, args);
      }
      return VariableNode(name.line, name.lexeme);
    }
    if (_match(FELTokenType.leftParen)) {
      final value = _expression();
      _consume(FELTokenType.rightParen, ') esperado');
      return value;
    }
    throw FELParserException('Expressão esperada', _peek);
  }

  bool _control(String v) => const {
    'IF',
    'ELSE',
    'WHILE',
    'FOR',
    'FOREACH',
    'RETURN',
    'BREAK',
    'CONTINUE',
  }.contains(v);
  bool _atEndOfStatement() =>
      _check(FELTokenType.newline) ||
      _check(FELTokenType.semicolon) ||
      _check(FELTokenType.eof) ||
      _check(FELTokenType.rightBrace);
  void _separators() {
    while (_matchAny([FELTokenType.newline, FELTokenType.semicolon])) {}
  }

  bool _keyword(String value) {
    if (_check(FELTokenType.keyword) && _peek.lexeme == value) {
      _current++;
      return true;
    }
    return false;
  }

  bool _match(FELTokenType type) {
    if (_check(type)) {
      _current++;
      return true;
    }
    return false;
  }

  bool _matchAny(List<FELTokenType> types) {
    for (final type in types) {
      if (_match(type)) return true;
    }
    return false;
  }

  FELToken _consume(FELTokenType type, String message) {
    if (_check(type)) return _advance;
    throw FELParserException(message, _peek);
  }

  FELToken _consumeAny(List<FELTokenType> types, String message) {
    for (final type in types) {
      if (_check(type)) return _advance;
    }
    throw FELParserException(message, _peek);
  }

  bool _check(FELTokenType type) => _peek.type == type;
  FELToken get _advance => tokens[_current++];
  FELToken get _peek => tokens[_current];
  FELToken get _previous => tokens[_current - 1];
}
