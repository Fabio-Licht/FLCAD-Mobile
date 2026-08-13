# FEL Lexer and Parser

The lexer emits tokens with line and column. The recursive-descent parser creates typed AST nodes and never executes callbacks. Command names may contain multiple words. A newline, semicolon, block boundary or pipeline arrow terminates command arguments.

The parser is intentionally dependency-free and portable to Dart Mobile/Desktop/Cloud services. Future grammar versions must preserve `.fel` version migration rather than silently changing semantics.
