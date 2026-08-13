abstract interface class EngineeringQuery<T> {
  String get name;
  String get projectId;
}

typedef EngineeringQueryHandler<T> =
    Future<T> Function(EngineeringQuery<T> query);

class EngineeringQueryBus {
  final Map<Type, dynamic> _handlers = {};
  void register<T>(EngineeringQueryHandler<T> handler) =>
      _handlers[EngineeringQuery<T>] = handler;
  Future<T> execute<T>(EngineeringQuery<T> query) {
    final handler =
        _handlers[EngineeringQuery<T>] as EngineeringQueryHandler<T>?;
    if (handler == null) throw StateError('No handler for ${query.name}');
    return handler(query);
  }
}
