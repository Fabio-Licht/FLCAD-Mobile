import 'command_context.dart';

class CommandValidationResult {
  const CommandValidationResult.valid() : message = null;
  const CommandValidationResult.invalid(this.message);
  final String? message;
  bool get isValid => message == null;
}

typedef CommandValidator =
    CommandValidationResult Function(
      CommandContext context,
      Map<String, Object?> parameters,
    );

class CommandValidation {
  const CommandValidation();

  static CommandValidationResult projectRequired(
    CommandContext context,
    Map<String, Object?> _,
  ) => context.hasProject
      ? const CommandValidationResult.valid()
      : const CommandValidationResult.invalid(
          'Create or open a project before executing this command.',
        );

  static CommandValidationResult selectionRequired(
    CommandContext context,
    Map<String, Object?> _,
  ) => context.selection.isNotEmpty
      ? const CommandValidationResult.valid()
      : const CommandValidationResult.invalid(
          'Select engineering geometry before executing this command.',
        );
}
