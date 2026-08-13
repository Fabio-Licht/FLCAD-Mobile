import '../compiler/fel_compiler.dart';
import '../lexer/fel_lexer.dart';
import '../optimizer/fel_optimizer.dart';
import '../parser/fel_parser.dart';
import '../runtime/fel_context.dart';
import '../runtime/fel_runtime.dart';
import '../validators/semantic_analyzer.dart';

class FELExecutor {
  FELExecutor({
    required this.runtime,
    required this.analyzer,
    FELCompiler? compiler,
  }) : compiler = compiler ?? FELCompiler();
  final FELRuntime runtime;
  final FELSemanticAnalyzer analyzer;
  final FELCompiler compiler;
  Future<FELExecutionResult> execute(
    String source,
    FELExecutionContext context, {
    FELCancellationToken? cancellation,
  }) async {
    final ast = FELParser(FELLexer().tokenize(source)).parse();
    final diagnostics = analyzer.analyze(ast).where((d) => d.isError).toList();
    if (diagnostics.isNotEmpty) {
      throw StateError(
        diagnostics.map((d) => '${d.line}: ${d.message}').join('\n'),
      );
    }
    final optimized = const FELOptimizer().optimize(ast);
    return runtime.execute(
      compiler.compile(source, optimized),
      context,
      cancellation: cancellation,
    );
  }
}
