import '../events/engineering_event_bus.dart';

abstract interface class EngineeringCommand<T> {
  String get name;
  String get projectId;
  Map<String, dynamic> get auditData;
}

class EngineeringCommandResult<T> {
  const EngineeringCommandResult(
    this.value, {
    this.undo,
    this.description = '',
  });
  final T value;
  final Future<void> Function()? undo;
  final String description;
}

typedef EngineeringCommandHandler<T> =
    Future<EngineeringCommandResult<T>> Function(EngineeringCommand<T> command);

class EngineeringCommandBus {
  EngineeringCommandBus({EngineeringEventBus? events})
    : events = events ?? EngineeringEventBus();
  final EngineeringEventBus events;
  final Map<Type, dynamic> _handlers = {};
  final List<EngineeringCommandResult<dynamic>> _undo = [], _redo = [];
  void register<T>(EngineeringCommandHandler<T> handler) =>
      _handlers[EngineeringCommand<T>] = handler;
  Future<EngineeringCommandResult<T>> execute<T>(
    EngineeringCommand<T> command,
  ) async {
    final handler =
        _handlers[EngineeringCommand<T>] as EngineeringCommandHandler<T>?;
    if (handler == null) throw StateError('No handler for ${command.name}');
    final result = await handler(command);
    _undo.add(result);
    _redo.clear();
    await events.publish(
      EngineeringEvent(
        id: 'cmd:${DateTime.now().microsecondsSinceEpoch}',
        projectId: command.projectId,
        domain: 'command',
        type: 'executed',
        entityId: command.name,
        timestamp: DateTime.now(),
        payload: command.auditData,
      ),
    );
    return result;
  }

  Future<void> undo() async {
    if (_undo.isEmpty) return;
    final result = _undo.removeLast();
    await result.undo?.call();
    _redo.add(result);
  }

  int get undoDepth => _undo.length;
}
