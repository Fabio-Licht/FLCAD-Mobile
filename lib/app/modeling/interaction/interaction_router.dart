import 'interaction_manager.dart';

class InteractionRouter {
  const InteractionRouter(this.manager);
  final InteractionManager manager;
  Future<void> activate(String toolId) => manager.activate(toolId);
  Future<void> parameter(String key, Object? value) =>
      manager.setParameter(key, value);
  Future<Object?> confirm() => manager.confirm();
  void cancel() => manager.cancel();
}
