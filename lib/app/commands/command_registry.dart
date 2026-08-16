import 'command_context.dart';
import 'command_validation.dart';

typedef CommandAction =
    Future<Object?> Function(
      CommandContext context,
      Map<String, Object?> parameters,
    );

class RegisteredEngineeringCommand {
  const RegisteredEngineeringCommand({
    required this.id,
    required this.module,
    required this.execute,
    required this.undo,
    required this.redo,
    this.validator,
  });
  final String id;
  final String module;
  final CommandAction execute;
  final CommandAction undo;
  final CommandAction redo;
  final CommandValidator? validator;
}

class CommandRegistry {
  final Map<String, RegisteredEngineeringCommand> _commands = {};
  Iterable<RegisteredEngineeringCommand> get commands => _commands.values;

  void register(RegisteredEngineeringCommand command) {
    if (_commands.containsKey(command.id)) {
      throw StateError('Command already registered: ${command.id}');
    }
    _commands[command.id] = command;
  }

  RegisteredEngineeringCommand resolve(String id) {
    final command = _commands[id];
    if (command == null) throw StateError('Command is not registered: $id');
    return command;
  }
}
