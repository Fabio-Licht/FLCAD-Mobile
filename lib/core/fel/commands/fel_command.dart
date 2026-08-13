import '../runtime/fel_context.dart';
import '../types/fel_type.dart';

class FELCommandResult {
  const FELCommandResult({
    required this.value,
    required this.description,
    this.undo,
  });
  final FELValue value;
  final String description;
  final Future<void> Function()? undo;
}

abstract interface class FELCommand {
  String get name;
  List<FELType> get argumentTypes;
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  );
}

class FELCommandRegistry {
  final Map<String, FELCommand> _commands = {};
  void register(FELCommand command) =>
      _commands[_normalize(command.name)] = command;
  FELCommand? unregister(String name) => _commands.remove(_normalize(name));
  FELCommand? find(String name) => _commands[_normalize(name)];
  List<String> get names => List.unmodifiable(_commands.keys);
  String _normalize(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
}
