import 'token.dart';

class FELLexer {
  static const keywords = {
    'LET',
    'CONST',
    'VAR',
    'IF',
    'ELSE',
    'FOR',
    'WHILE',
    'FOREACH',
    'SWITCH',
    'RETURN',
    'BREAK',
    'CONTINUE',
    'TRUE',
    'FALSE',
    'PIPELINE',
    'FUNCTION',
    'IN',
  };
  List<FELToken> tokenize(String source) {
    final tokens = <FELToken>[];
    var i = 0, line = 1, column = 1;
    while (i < source.length) {
      final c = source[i];
      if (c == ' ' || c == '\t' || c == '\r') {
        i++;
        column++;
        continue;
      }
      if (c == '\n') {
        tokens.add(FELToken(FELTokenType.newline, '\n', line, column));
        i++;
        line++;
        column = 1;
        continue;
      }
      if (c == '#' ||
          (c == '/' && i + 1 < source.length && source[i + 1] == '/')) {
        while (i < source.length && source[i] != '\n') {
          i++;
          column++;
        }
        continue;
      }
      if (c == '"') {
        final start = column;
        i++;
        column++;
        final b = StringBuffer();
        while (i < source.length && source[i] != '"') {
          if (source[i] == '\n') {
            throw FELLexerException('String não terminada', line, start);
          }
          b.write(source[i++]);
          column++;
        }
        if (i >= source.length) {
          throw FELLexerException('String não terminada', line, start);
        }
        i++;
        column++;
        tokens.add(
          FELToken(
            FELTokenType.string,
            b.toString(),
            line,
            start,
            literal: b.toString(),
          ),
        );
        continue;
      }
      if (_digit(c)) {
        final start = i, startColumn = column;
        while (i < source.length && (_digit(source[i]) || source[i] == '.')) {
          i++;
          column++;
        }
        final text = source.substring(start, i);
        tokens.add(
          FELToken(
            FELTokenType.number,
            text,
            line,
            startColumn,
            literal: double.parse(text),
          ),
        );
        continue;
      }
      if (_alpha(c)) {
        final start = i, startColumn = column;
        while (i < source.length &&
            (_alpha(source[i]) || _digit(source[i]) || source[i] == '_')) {
          i++;
          column++;
        }
        final upper = source.substring(start, i).toUpperCase();
        tokens.add(
          FELToken(
            keywords.contains(upper)
                ? FELTokenType.keyword
                : FELTokenType.identifier,
            upper,
            line,
            startColumn,
            literal: upper,
          ),
        );
        continue;
      }
      final startColumn = column;
      FELTokenType? type;
      var lexeme = c;
      if (i + 1 < source.length) {
        final pair = source.substring(i, i + 2);
        final paired = {
          '->': FELTokenType.arrow,
          '==': FELTokenType.equalEqual,
          '!=': FELTokenType.bangEqual,
          '>=': FELTokenType.greaterEqual,
          '<=': FELTokenType.lessEqual,
        }[pair];
        if (paired != null) {
          type = paired;
          lexeme = pair;
        }
      }
      type ??= {
        '=': FELTokenType.equals,
        '+': FELTokenType.plus,
        '-': FELTokenType.minus,
        '*': FELTokenType.star,
        '/': FELTokenType.slash,
        '>': FELTokenType.greater,
        '<': FELTokenType.less,
        '(': FELTokenType.leftParen,
        ')': FELTokenType.rightParen,
        '{': FELTokenType.leftBrace,
        '}': FELTokenType.rightBrace,
        ',': FELTokenType.comma,
        ';': FELTokenType.semicolon,
      }[c];
      if (type == null) {
        throw FELLexerException('Caractere inválido: $c', line, column);
      }
      tokens.add(FELToken(type, lexeme, line, startColumn));
      i += lexeme.length;
      column += lexeme.length;
    }
    tokens.add(FELToken(FELTokenType.eof, '', line, column));
    return tokens;
  }

  bool _digit(String c) => RegExp(r'[0-9]').hasMatch(c);
  bool _alpha(String c) => RegExp(r'[A-Za-z_]').hasMatch(c);
}
