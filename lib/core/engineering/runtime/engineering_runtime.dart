import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

enum EngineeringTaskPriority { low, normal, high, critical }

enum EngineeringTaskState {
  queued,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

class EngineeringCancellationToken {
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw StateError('Engineering task cancelled');
  }
}

class EngineeringTaskProgress {
  const EngineeringTaskProgress(this.value, {this.message});
  final double value;
  final String? message;
}

class EngineeringTask<T> {
  EngineeringTask(
    this.id,
    this.future,
    this.token, {
    this.namespace = 'engineering',
  });
  final String id;
  final Future<T> future;
  final EngineeringCancellationToken token;
  final String namespace;
}

class EngineeringRuntimeMetrics {
  const EngineeringRuntimeMetrics({
    required this.queued,
    required this.running,
    required this.completed,
    required this.failed,
    required this.cancelled,
    required this.totalDuration,
  });
  final int queued, running, completed, failed, cancelled;
  final Duration totalDuration;
}

/// Shared Runtime 2.0 used by engineering domains.
///
/// Work is bounded by [workerCount], ordered by priority and isolated by
/// default. Domain runtimes should delegate to this class instead of owning
/// worker lifecycle, cancellation and scheduling independently.
class EngineeringRuntime {
  static final shared = EngineeringRuntime();
  EngineeringRuntime({int? workerCount}) : workerCount = workerCount ?? 2 {
    if (this.workerCount < 1) {
      throw ArgumentError.value(workerCount, 'workerCount');
    }
  }

  final int workerCount;
  final Map<String, _QueuedTask<dynamic>> _tasks = {};
  final List<_QueuedTask<dynamic>> _queue = [];
  int _running = 0, _completed = 0, _failed = 0, _cancelled = 0;
  Duration _totalDuration = Duration.zero;
  bool _paused = false, _disposed = false;

  EngineeringTask<T> submit<T>(
    String id,
    FutureOr<T> Function() operation, {
    EngineeringCancellationToken? token,
    EngineeringTaskPriority priority = EngineeringTaskPriority.normal,
    String namespace = 'engineering',
    void Function(EngineeringTaskProgress progress)? onProgress,
    bool runInIsolate = true,
  }) {
    if (_disposed) throw StateError('Engineering runtime is disposed');
    if (_tasks.containsKey(id)) throw StateError('Task $id is already active');
    final cancellation = token ?? EngineeringCancellationToken();
    final completer = Completer<T>();
    final queued = _QueuedTask<T>(
      id: id,
      operation: operation,
      token: cancellation,
      priority: priority,
      namespace: namespace,
      completer: completer,
      onProgress: onProgress,
      sequence: _sequence++,
      runInIsolate: runInIsolate,
    );
    _tasks[id] = queued;
    _queue.add(queued);
    _queue.sort((a, b) {
      final priorityOrder = b.priority.index.compareTo(a.priority.index);
      return priorityOrder != 0
          ? priorityOrder
          : a.sequence.compareTo(b.sequence);
    });
    _drain();
    return EngineeringTask<T>(
      id,
      completer.future,
      cancellation,
      namespace: namespace,
    );
  }

  static int _sequence = 0;

  void pause() => _paused = true;
  void resume() {
    _paused = false;
    _drain();
  }

  bool cancel(String id) {
    final task = _tasks[id];
    if (task == null) return false;
    task.token.cancel();
    if (_queue.remove(task)) {
      _tasks.remove(id);
      _cancelled++;
      task.completeError(StateError('Engineering task cancelled'));
    }
    return true;
  }

  void cancelNamespace(String namespace) {
    for (final id
        in _tasks.values
            .where((t) => t.namespace == namespace)
            .map((t) => t.id)
            .toList()) {
      cancel(id);
    }
  }

  void _drain() {
    if (_paused || _disposed) return;
    while (_running < workerCount && _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      if (task.token.cancelled) continue;
      _running++;
      task.run().whenComplete(() {
        _running--;
        _tasks.remove(task.id);
        _totalDuration += task.elapsed;
        switch (task.state) {
          case EngineeringTaskState.completed:
            _completed++;
          case EngineeringTaskState.failed:
            _failed++;
          case EngineeringTaskState.cancelled:
            _cancelled++;
          default:
            break;
        }
        _drain();
      });
    }
  }

  EngineeringRuntimeMetrics get metrics => EngineeringRuntimeMetrics(
    queued: _queue.length,
    running: _running,
    completed: _completed,
    failed: _failed,
    cancelled: _cancelled,
    totalDuration: _totalDuration,
  );
  bool get paused => _paused;
  int get activeTasks => _tasks.length;
  UnmodifiableListView<String> get queuedTaskIds =>
      UnmodifiableListView(_queue.map((e) => e.id));

  Future<void> dispose() async {
    _disposed = true;
    for (final id in _tasks.keys.toList()) {
      cancel(id);
    }
  }
}

class _QueuedTask<T> {
  _QueuedTask({
    required this.id,
    required this.operation,
    required this.token,
    required this.priority,
    required this.namespace,
    required this.completer,
    required this.sequence,
    required this.runInIsolate,
    this.onProgress,
  });
  final String id, namespace;
  final FutureOr<T> Function() operation;
  final EngineeringCancellationToken token;
  final EngineeringTaskPriority priority;
  final Completer<T> completer;
  final int sequence;
  final bool runInIsolate;
  final void Function(EngineeringTaskProgress progress)? onProgress;
  EngineeringTaskState state = EngineeringTaskState.queued;
  Duration elapsed = Duration.zero;

  Future<void> run() async {
    final stopwatch = Stopwatch()..start();
    state = EngineeringTaskState.running;
    onProgress?.call(const EngineeringTaskProgress(0));
    try {
      token.throwIfCancelled();
      final value = await (runInIsolate
          ? Isolate.run(operation)
          : Future<T>.sync(operation));
      token.throwIfCancelled();
      state = EngineeringTaskState.completed;
      onProgress?.call(const EngineeringTaskProgress(1));
      if (!completer.isCompleted) completer.complete(value);
    } catch (error, stackTrace) {
      state = token.cancelled
          ? EngineeringTaskState.cancelled
          : EngineeringTaskState.failed;
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    } finally {
      stopwatch.stop();
      elapsed = stopwatch.elapsed;
    }
  }

  void completeError(Object error) {
    state = EngineeringTaskState.cancelled;
    if (!completer.isCompleted) completer.completeError(error);
  }
}
