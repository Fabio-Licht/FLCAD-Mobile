import '../ast/ast_nodes.dart';

class FELInstruction {
  const FELInstruction(this.node, this.index);
  final StatementNode node;
  final int index;
}

class FELProgram {
  const FELProgram({
    required this.sourceHash,
    required this.source,
    required this.ast,
    required this.instructions,
  });
  final int sourceHash;
  final String source;
  final ProgramNode ast;
  final List<FELInstruction> instructions;
}

class FELCompiler {
  final Map<int, FELProgram> _cache = {};
  FELProgram compile(String source, ProgramNode ast) {
    final hash = source.hashCode;
    return _cache.putIfAbsent(
      hash,
      () => FELProgram(
        sourceHash: hash,
        source: source,
        ast: ast,
        instructions: List.generate(
          ast.statements.length,
          (i) => FELInstruction(ast.statements[i], i),
        ),
      ),
    );
  }

  void invalidate() => _cache.clear();
}
