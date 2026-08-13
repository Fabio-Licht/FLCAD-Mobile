enum FELTokenType {
  identifier,
  number,
  string,
  keyword,
  arrow,
  equals,
  plus,
  minus,
  star,
  slash,
  greater,
  less,
  greaterEqual,
  lessEqual,
  equalEqual,
  bangEqual,
  leftParen,
  rightParen,
  leftBrace,
  rightBrace,
  comma,
  semicolon,
  newline,
  eof,
}

class FELToken {
  const FELToken(
    this.type,
    this.lexeme,
    this.line,
    this.column, {
    this.literal,
  });
  final FELTokenType type;
  final String lexeme;
  final int line, column;
  final Object? literal;
  @override
  String toString() => '${type.name}($lexeme)@$line:$column';
}

class FELLexerException implements Exception {
  const FELLexerException(this.message, this.line, this.column);
  final String message;
  final int line, column;
  @override
  String toString() => 'FELLexerException $line:$column $message';
}
