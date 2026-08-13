import 'dart:async';
import '../../engineering/runtime/engineering_runtime.dart';
import '../precision/precision.dart';

class KernelExecutionMetrics {
  const KernelExecutionMetrics(this.operation, this.elapsed, this.success);
  final String operation;
  final Duration elapsed;
  final bool success;
}

typedef KernelMetricsSink = void Function(KernelExecutionMetrics metrics);

class GeometricKernelRuntime {
  const GeometricKernelRuntime({
    this.precision = const PrecisionContext(),
    this.metricsSink,
  });
  final PrecisionContext precision;
  final KernelMetricsSink? metricsSink;
  T execute<T>(String operation, T Function() body) {
    final watch = Stopwatch()..start();
    try {
      final result = body();
      metricsSink?.call(KernelExecutionMetrics(operation, watch.elapsed, true));
      return result;
    } catch (_) {
      metricsSink?.call(
        KernelExecutionMetrics(operation, watch.elapsed, false),
      );
      rethrow;
    }
  }
}

abstract interface class GeometricComputeBackend {
  String get name;
  bool get isAvailable;
  Future<T> schedule<T>(String operation, FutureOr<T> Function() computation);
}

abstract interface class RemoteGeometricKernel {
  Future<Map<String, dynamic>> execute(
    String projectId,
    String operation,
    Map<String, dynamic> payload,
  );
}

class KernelCancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw StateError('Kernel task cancelled');
  }
}

class GeometricTaskScheduler {
  Future<T> run<T>(
    FutureOr<T> Function() computation, {
    KernelCancellationToken? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final result = await EngineeringRuntime.shared
        .submit(
          'geometry:${DateTime.now().microsecondsSinceEpoch}',
          computation,
          namespace: 'geometry',
        )
        .future;
    cancellation?.throwIfCancelled();
    return result;
  }
}
