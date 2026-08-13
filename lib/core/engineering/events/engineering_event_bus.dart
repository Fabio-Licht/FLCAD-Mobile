import 'dart:async';

enum EngineeringEventPriority { low, normal, high, critical }

class EngineeringEvent {
  const EngineeringEvent({
    required this.id,
    required this.projectId,
    required this.domain,
    required this.type,
    required this.entityId,
    required this.timestamp,
    this.payload = const {},
    this.priority = EngineeringEventPriority.normal,
    this.correlationId,
  });
  final String id, projectId, domain, type, entityId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final EngineeringEventPriority priority;
  final String? correlationId;
}

typedef EngineeringEventFilter = bool Function(EngineeringEvent event);

class EngineeringSubscription {
  EngineeringSubscription(this._cancel);
  final void Function() _cancel;
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _cancel();
    }
  }
}

class EngineeringEventBus {
  final _listeners = <int, _EventListener>{};
  final _replay = <EngineeringEvent>[];
  int _next = 0;
  Future<void> publish(EngineeringEvent event) async {
    _replay.add(event);
    final listeners =
        _listeners.values
            .where((l) => !l.subscription.cancelled && l.filter(event))
            .toList()
          ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    for (final listener in listeners) {
      await listener.callback(event);
    }
  }

  EngineeringSubscription subscribe(
    FutureOr<void> Function(EngineeringEvent) callback, {
    EngineeringEventFilter? filter,
    EngineeringEventPriority priority = EngineeringEventPriority.normal,
    bool replay = false,
  }) {
    final id = _next++,
        subscription = EngineeringSubscription(() => _listeners.remove(id)),
        listener = _EventListener(
          callback,
          filter ?? (_) => true,
          priority,
          subscription,
        );
    _listeners[id] = listener;
    if (replay) {
      for (final event in _replay.where(listener.filter)) {
        Future.sync(() => callback(event));
      }
    }
    return subscription;
  }

  List<EngineeringEvent> query({
    String? domain,
    String? type,
    String? entityId,
  }) => List.unmodifiable(
    _replay.where(
      (e) =>
          (domain == null || e.domain == domain) &&
          (type == null || e.type == type) &&
          (entityId == null || e.entityId == entityId),
    ),
  );
}

class _EventListener {
  const _EventListener(
    this.callback,
    this.filter,
    this.priority,
    this.subscription,
  );
  final FutureOr<void> Function(EngineeringEvent) callback;
  final EngineeringEventFilter filter;
  final EngineeringEventPriority priority;
  final EngineeringSubscription subscription;
}
