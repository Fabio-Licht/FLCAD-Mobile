import 'command_dispatcher.dart';

class UndoCommandAdapter {
  const UndoCommandAdapter(this.dispatcher);
  final CommandDispatcher dispatcher;
  bool get canUndo => dispatcher.manager.canUndo;
  bool get canRedo => dispatcher.manager.canRedo;
  Future<void> undo() => dispatcher.undo();
  Future<void> redo() => dispatcher.redo();
}
