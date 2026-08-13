class EngineeringServiceRegistry {
  final Map<Type, Object> _services = {};
  void register<T extends Object>(T service) => _services[T] = service;
  T get<T extends Object>() =>
      _services[T] as T? ?? (throw StateError('Service $T not registered'));
  T? find<T extends Object>() => _services[T] as T?;
  bool contains<T extends Object>() => _services.containsKey(T);
  Iterable<Type> get types => _services.keys;
}
