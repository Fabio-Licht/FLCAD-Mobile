import 'command_dispatcher.dart';

class EngineeringCommandRouter {
  const EngineeringCommandRouter(this.dispatcher);
  final CommandDispatcher dispatcher;
  Future<Object?> route(
    String commandId, [
    Map<String, Object?> parameters = const {},
  ]) => dispatcher.dispatch(commandId, parameters);
}
