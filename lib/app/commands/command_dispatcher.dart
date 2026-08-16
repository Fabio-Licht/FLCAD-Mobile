import 'package:flutter/foundation.dart';

import 'command_context.dart';
import 'command_manager.dart';

class CommandDispatcher extends ChangeNotifier {
  CommandDispatcher({required this.manager, required CommandContext context})
    : _context = context;
  final CommandManager manager;
  CommandContext _context;
  CommandContext get context => _context;
  Object? lastResult;
  Object? lastError;

  void updateContext(CommandContext value) {
    _context = value;
    notifyListeners();
  }

  Future<Object?> dispatch(
    String id, [
    Map<String, Object?> parameters = const {},
  ]) async {
    try {
      lastError = null;
      lastResult = await manager.execute(id, _context, parameters);
      notifyListeners();
      return lastResult;
    } catch (error) {
      lastError = error;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> undo() async {
    lastResult = await manager.undo();
    notifyListeners();
  }

  Future<void> redo() async {
    lastResult = await manager.redo();
    notifyListeners();
  }
}
