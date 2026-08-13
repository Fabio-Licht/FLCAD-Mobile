import 'dart:io';

import 'package:flcad_mobile/core/fel/ast/ast_nodes.dart';
import 'package:flcad_mobile/core/fel/commands/fel_command.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/fel/functions/fel_function_library.dart';
import 'package:flcad_mobile/core/fel/lexer/fel_lexer.dart';
import 'package:flcad_mobile/core/fel/macros/fel_macro.dart';
import 'package:flcad_mobile/core/fel/parser/fel_parser.dart';
import 'package:flcad_mobile/core/fel/plugins/fel_plugin.dart';
import 'package:flcad_mobile/core/fel/serializer/fel_serializer.dart';
import 'package:flcad_mobile/core/fel/types/fel_type.dart';
import 'package:flcad_mobile/core/fel/validators/semantic_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lexer and parser create AST for variables, conditions and pipelines', () {
    const source =
        'LET RINGS = 2\nIF RINGS > 1 {\nSELECT REGION "FLANGE" -> SHRINK REGION 1 -> SAVE PROJECT\n}';
    final tokens = FELLexer().tokenize(source);
    expect(tokens.any((t) => t.lexeme == '->'), isTrue);
    final ast = FELParser(tokens).parse();
    expect(ast.statements.first, isA<VariableDeclarationNode>());
    expect(ast.statements[1], isA<ConditionNode>());
    final condition = ast.statements[1] as ConditionNode;
    expect(condition.thenBranch.single, isA<PipelineNode>());
    expect(
      (condition.thenBranch.single as PipelineNode).commands,
      hasLength(3),
    );
  });

  test(
    'semantic analyzer rejects unknown variables, functions and commands',
    () {
      final commands = createNativeCommandRegistry(),
          functions = FELFunctionLibrary();
      final ast = FELParser(
        FELLexer().tokenize('UNKNOWN VALUE\nLET X = MISSING(UNDEFINED)'),
      ).parse();
      final diagnostics = FELSemanticAnalyzer(commands, functions).analyze(ast);
      expect(
        diagnostics.map((d) => d.message).join(' '),
        contains('Comando não registrado'),
      );
      expect(
        diagnostics.map((d) => d.message).join(' '),
        contains('Função inexistente'),
      );
      expect(
        diagnostics.map((d) => d.message).join(' '),
        contains('Variável inexistente'),
      );
    },
  );

  test('macros record FEL and serializer enforces .fel', () async {
    final recorder = FELMacroRecorder()..start();
    recorder.record('SELECT REGION "TOP"');
    recorder.record('SAVE PROJECT');
    final macro = recorder.stop('Top');
    expect(macro.source, contains('SAVE PROJECT'));
    final root = await Directory.systemTemp.createTemp('fel_');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/flow.fel';
    await const FELSerializer().save(macro.source, path);
    expect(await const FELSerializer().load(path), macro.source);
    await expectLater(
      const FELSerializer().save('', '${root.path}/bad.txt'),
      throwsArgumentError,
    );
  });

  test('plugins register and hot-unload external commands', () {
    final registry = FELCommandRegistry(),
        manager = FELPluginManager(),
        command = _NoopCommand();
    manager.load(
      FELPlugin(id: 'plugin', version: '1', commands: [command]),
      registry,
    );
    expect(registry.find('CREATE TURBINE'), same(command));
    manager.unload('plugin', registry);
    expect(registry.find('CREATE TURBINE'), isNull);
  });
}

class _NoopCommand implements FELCommand {
  @override
  String get name => 'CREATE TURBINE';
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    dynamic context,
    List<FELValue> arguments,
  ) async =>
      const FELCommandResult(value: FELValue.voidValue, description: 'ok');
}
