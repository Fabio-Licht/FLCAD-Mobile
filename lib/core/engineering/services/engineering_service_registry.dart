class EngineeringServiceRegistry {
  final Map<Type, Object> _services = {};
  final Map<Type, Object Function(EngineeringServiceRegistry)> _factories = {};
  void register<T extends Object>(T service, {bool replace = false}) {
    if (!replace && contains<T>()) {
      throw StateError('Service $T already registered');
    }
    _services[T] = service;
  }

  void registerFactory<T extends Object>(
    T Function(EngineeringServiceRegistry registry) factory, {
    bool replace = false,
  }) {
    if (!replace && (_services.containsKey(T) || _factories.containsKey(T))) {
      throw StateError('Service $T already registered');
    }
    _factories[T] = factory;
  }

  T get<T extends Object>() =>
      find<T>() ?? (throw StateError('Service $T not registered'));
  T? find<T extends Object>() {
    final current = _services[T];
    if (current != null) return current as T;
    final factory = _factories[T];
    if (factory == null) return null;
    final created = factory(this);
    _services[T] = created;
    return created as T;
  }

  bool contains<T extends Object>() =>
      _services.containsKey(T) || _factories.containsKey(T);
  Iterable<Type> get types => {..._services.keys, ..._factories.keys};
}
