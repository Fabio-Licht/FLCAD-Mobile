import '../ast/ast_nodes.dart';
import '../commands/fel_command.dart';
import '../compiler/fel_compiler.dart';
import '../debugger/fel_debugger.dart';
import '../functions/fel_function_library.dart';
import '../history/fel_history.dart';
import '../history/fel_history_repository.dart';
import '../types/fel_type.dart';
import 'fel_context.dart';

enum FELRuntimeState { idle, running, paused, cancelled, completed, failed }

class FELCancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class FELExecutionResult {
  const FELExecutionResult(this.state, this.value, this.executed, this.error);
  final FELRuntimeState state;
  final FELValue value;
  final int executed;
  final String? error;
}

class FELRuntime {
  FELRuntime({
    required this.commands,
    required this.functions,
    FELDebugger? debugger,
    FELHistory? history,
    FELHistoryRepository? historyRepository,
  }) : debugger = debugger ?? FELDebugger(),
       history = history ?? FELHistory(),
       historyRepository = historyRepository ?? FELHistoryRepository();
  final FELCommandRegistry commands;
  final FELFunctionLibrary functions;
  final FELDebugger debugger;
  final FELHistory history;
  final FELHistoryRepository historyRepository;
  FELRuntimeState state = FELRuntimeState.idle;
  FELCancellationToken? _token;
  Future<FELExecutionResult> execute(
    FELProgram program,
    FELExecutionContext context, {
    FELCancellationToken? cancellation,
  }) async {
    state = FELRuntimeState.running;
    _token = cancellation ?? FELCancellationToken();
    var count = 0;
    try {
      for (final instruction in program.instructions) {
        await _checkpoint();
        await _statement(instruction.node, context, program.source);
        count++;
      }
      state = FELRuntimeState.completed;
      return FELExecutionResult(state, context.pipelineValue, count, null);
    } catch (error) {
      if (_token!.isCancelled) {
        state = FELRuntimeState.cancelled;
        return FELExecutionResult(state, context.pipelineValue, count, null);
      }
      state = FELRuntimeState.failed;
      return FELExecutionResult(
        state,
        context.pipelineValue,
        count,
        error.toString(),
      );
    }
  }

  void cancel() {
    _token?.cancel();
    if (state == FELRuntimeState.paused) resume();
  }

  void pause() {
    if (state == FELRuntimeState.running) state = FELRuntimeState.paused;
  }

  void resume() {
    if (state == FELRuntimeState.paused) {
      state = FELRuntimeState.running;
    }
  }

  Future<void> _checkpoint() async {
    if (_token?.isCancelled == true) throw const _Cancelled();
    while (state == FELRuntimeState.paused) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    if (_token?.isCancelled == true) throw const _Cancelled();
  }

  Future<void> _statement(
    StatementNode node,
    FELExecutionContext c,
    String source,
  ) async {
    switch (node) {
      case CommandNode():
        await _command(node, c, source);
      case PipelineNode():
        for (final command in node.commands) {
          await _checkpoint();
          await _command(command, c, source);
        }
      case VariableDeclarationNode():
        c.variables[node.name] = _expression(node.initializer, c);
      case ConditionNode():
        final branch = (_expression(node.condition, c).value as bool)
            ? node.thenBranch
            : node.elseBranch;
        for (final child in branch) {
          await _statement(child, c, source);
        }
      case LoopNode():
        var guard = 0;
        while (_expression(node.condition, c).value == true) {
          if (guard++ > 10000) throw StateError('Limite de loop excedido');
          for (final child in node.body) {
            await _statement(child, c, source);
          }
        }
      case ReturnNode():
        c.pipelineValue = node.value == null
            ? FELValue.voidValue
            : _expression(node.value!, c);
      default:
        break;
    }
  }

  Future<void> _command(
    CommandNode node,
    FELExecutionContext c,
    String source,
  ) async {
    final command = commands.find(node.name);
    if (command == null) {
      throw StateError('Comando não registrado: ${node.name}');
    }
    final args = node.arguments.map((e) => _expression(e, c)).toList(),
        watch = Stopwatch()..start();
    try {
      final result = await command.execute(c, args);
      watch.stop();
      c.pipelineValue = result.value;
      debugger.record(
        FELDebugEntry(
          line: node.line,
          command: node.name,
          duration: watch.elapsed,
          result: result.description,
        ),
      );
      history.record(
        FELHistoryEntry(
          source: source,
          command: node.name,
          timestamp: DateTime.now(),
          description: result.description,
          undo: result.undo,
        ),
      );
      if (c.projectPath.isNotEmpty) {
        await historyRepository.append(
          projectPath: c.projectPath,
          source: source,
          command: node.name,
          description: result.description,
        );
      }
    } catch (error) {
      watch.stop();
      debugger.record(
        FELDebugEntry(
          line: node.line,
          command: node.name,
          duration: watch.elapsed,
          result: '',
          error: error.toString(),
        ),
      );
      rethrow;
    }
  }

  FELValue _expression(ExpressionNode n, FELExecutionContext c) {
    if (n is LiteralNode) return FELValue(n.valueType, n.value);
    if (n is VariableNode) {
      final value = c.variables[n.name];
      if (value == null) throw StateError('Variável inexistente: ${n.name}');
      return value;
    }
    if (n is FunctionCallNode) {
      final function = functions.find(n.name);
      if (function == null) throw StateError('Função inexistente: ${n.name}');
      return function(n.arguments.map((e) => _expression(e, c)).toList());
    }
    if (n is BinaryExpressionNode) {
      return _binary(
        _expression(n.left, c),
        n.operator,
        _expression(n.right, c),
      );
    }
    if (n is RegionNode) return FELValue(FELType.region, n.reference);
    if (n is MeshNode) return FELValue(FELType.mesh, n.reference);
    if (n is CADNode) return FELValue(n.cadType, n.reference);
    throw StateError('Expressão não suportada: ${n.runtimeType}');
  }

  FELValue _binary(FELValue a, String op, FELValue b) {
    final x = a.value, y = b.value;
    return switch (op) {
      '+' => FELValue(FELType.number, (x as num) + (y as num)),
      '-' => FELValue(FELType.number, (x as num) - (y as num)),
      '*' => FELValue(FELType.number, (x as num) * (y as num)),
      '/' => FELValue(FELType.number, (x as num) / (y as num)),
      '>' => FELValue(FELType.boolean, (x as num) > (y as num)),
      '>=' => FELValue(FELType.boolean, (x as num) >= (y as num)),
      '<' => FELValue(FELType.boolean, (x as num) < (y as num)),
      '<=' => FELValue(FELType.boolean, (x as num) <= (y as num)),
      '==' => FELValue(FELType.boolean, x == y),
      '!=' => FELValue(FELType.boolean, x != y),
      _ => throw StateError('Operador inválido: $op'),
    };
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
