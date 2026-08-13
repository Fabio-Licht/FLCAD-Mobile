import 'dart:async';
import 'dart:isolate';

class EngineeringCancellationToken {
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw StateError('Engineering task cancelled');
  }
}

class EngineeringTask<T> {
  EngineeringTask(this.id, this.future, this.token);
  final String id;
  final Future<T> future;
  final EngineeringCancellationToken token;
}

class EngineeringRuntime {
  final Map<String, EngineeringTask<dynamic>> _tasks = {};
  EngineeringTask<T> submit<T>(
    String id,
    T Function() operation, {
    EngineeringCancellationToken? token,
  }) {
    final cancellation = token ?? EngineeringCancellationToken();
    final future = Isolate.run(() => operation())
        .then((value) {
          cancellation.throwIfCancelled();
          return value;
        })
        .whenComplete(() => _tasks.remove(id));
    final task = EngineeringTask<T>(id, future, cancellation);
    _tasks[id] = task;
    return task;
  }

  bool cancel(String id) {
    final task = _tasks[id];
    if (task == null) return false;
    task.token.cancel();
    return true;
  }

  int get activeTasks => _tasks.length;
}
