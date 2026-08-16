import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'command_context.dart';
import 'command_registry.dart';

class CommandExecutionRecord {
  const CommandExecutionRecord({
    required this.commandId,
    required this.module,
    required this.parameters,
    required this.result,
    required this.timestamp,
    required this.durationMicros,
    required this.operation,
  });
  final String commandId;
  final String module;
  final Map<String, Object?> parameters;
  final String result;
  final DateTime timestamp;
  final int durationMicros;
  final String operation;
  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'command': commandId,
    'module': module,
    'parameters': parameters,
    'result': result,
    'durationMicros': durationMicros,
    'operation': operation,
  };
}

class CommandManager {
  CommandManager({
    required this.registry,
    DateTime Function()? clock,
    int Function()? durationProvider,
  }) : clock = clock ?? DateTime.now,
       durationProvider = durationProvider ?? (() => 0);
  final CommandRegistry registry;
  final DateTime Function() clock;
  final int Function() durationProvider;
  final List<_ExecutedCommand> _undo = [];
  final List<_ExecutedCommand> _redo = [];
  final List<CommandExecutionRecord> history = [];
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  Future<Object?> execute(
    String id,
    CommandContext context, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final command = registry.resolve(id);
    final validation = command.validator?.call(context, parameters);
    if (validation != null && !validation.isValid) {
      throw StateError(validation.message!);
    }
    final result = await command.execute(context, parameters);
    _undo.add(_ExecutedCommand(command, context, parameters));
    _redo.clear();
    await _record(command, context, parameters, result, 'execute');
    return result;
  }

  Future<Object?> undo() async {
    if (_undo.isEmpty) throw StateError('There is no command to undo.');
    final executed = _undo.removeLast();
    final result = await executed.command.undo(
      executed.context,
      executed.parameters,
    );
    _redo.add(executed);
    await _record(
      executed.command,
      executed.context,
      executed.parameters,
      result,
      'undo',
    );
    return result;
  }

  Future<Object?> redo() async {
    if (_redo.isEmpty) throw StateError('There is no command to redo.');
    final executed = _redo.removeLast();
    final result = await executed.command.redo(
      executed.context,
      executed.parameters,
    );
    _undo.add(executed);
    await _record(
      executed.command,
      executed.context,
      executed.parameters,
      result,
      'redo',
    );
    return result;
  }

  Future<void> _record(
    RegisteredEngineeringCommand command,
    CommandContext context,
    Map<String, Object?> parameters,
    Object? result,
    String operation,
  ) async {
    final record = CommandExecutionRecord(
      commandId: command.id,
      module: command.module,
      parameters: parameters,
      result: result?.toString() ?? 'completed',
      timestamp: clock(),
      durationMicros: durationProvider(),
      operation: operation,
    );
    history.add(record);
    final root = context.projectDirectory;
    if (root == null) return;
    final folder = switch (operation) {
      'undo' => 'UndoHistory',
      'redo' => 'RedoHistory',
      _ => 'CommandHistory',
    };
    final directory = Directory(path.join(root.path, 'CAD', folder));
    await directory.create(recursive: true);
    await File(path.join(directory.path, 'history.jsonl')).writeAsString(
      '${jsonEncode(record.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}

class _ExecutedCommand {
  const _ExecutedCommand(this.command, this.context, this.parameters);
  final RegisteredEngineeringCommand command;
  final CommandContext context;
  final Map<String, Object?> parameters;
}
