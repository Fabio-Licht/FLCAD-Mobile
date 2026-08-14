import 'dart:async';
import 'dart:isolate';

import '../domain/reconstruction_backend.dart';
import '../models/pipeline_event.dart';
import '../models/pipeline_progress.dart';
import '../models/pipeline_result.dart';
import '../pipeline/pipeline_context.dart';
import '../pipeline/pipeline_step.dart';
import '../pipeline/reconstruction_pipeline.dart';
import '../pipeline/standard_steps.dart';

class IsolateAlphaReconstructionBackend implements ReconstructionBackend {
  Isolate? _isolate;
  SendPort? _control;

  @override
  Future<PipelineResult> run(
    PipelineContext context, {
    required void Function(PipelineProgress progress) onProgress,
    required void Function(PipelineEvent event) onEvent,
  }) async {
    await dispose();
    final receive = ReceivePort();
    final errors = ReceivePort();
    final completer = Completer<PipelineResult>();
    late final StreamSubscription subscription;
    late final StreamSubscription errorSubscription;
    subscription = receive.listen((message) {
      if (message is SendPort) {
        _control = message;
        return;
      }
      if (message is! Map) return;
      final data = message.cast<String, dynamic>();
      switch (data['kind']) {
        case 'progress':
          onProgress(
            PipelineProgress.fromJson(
              (data['data'] as Map).cast<String, dynamic>(),
            ),
          );
        case 'event':
          onEvent(
            PipelineEvent.fromJson(
              (data['data'] as Map).cast<String, dynamic>(),
            ),
          );
        case 'result':
          if (!completer.isCompleted) {
            completer.complete(
              PipelineResult.fromJson(
                (data['data'] as Map).cast<String, dynamic>(),
              ),
            );
          }
      }
    });
    errorSubscription = errors.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(
          PipelineResult(
            success: false,
            cancelled: false,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
            completedSteps: const [],
            resultPath: null,
            error: message.toString(),
          ),
        );
      }
    });
    _isolate = await Isolate.spawn(_isolateEntry, {
      'reply': receive.sendPort,
      'context': context.toJson(),
    }, onError: errors.sendPort);
    try {
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Reconstruction isolate did not respond within 30 seconds',
        ),
      );
    } finally {
      await subscription.cancel();
      await errorSubscription.cancel();
      receive.close();
      errors.close();
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _control = null;
    }
  }

  @override
  void cancel() => _control?.send('cancel');
  @override
  Future<void> dispose() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _control = null;
  }

  static Future<void> _isolateEntry(Map<String, dynamic> message) async {
    final reply = message['reply'] as SendPort;
    final control = ReceivePort();
    final cancellation = PipelineCancellationToken();
    control.listen((message) {
      if (message == 'cancel') cancellation.cancel();
    });
    reply.send(control.sendPort);
    final context = PipelineContext.fromJson(
      (message['context'] as Map).cast<String, dynamic>(),
    );
    final pipeline = ReconstructionPipeline(
      steps: createStandardPipelineSteps(),
    );
    final result = await pipeline.run(
      context,
      cancellation: cancellation,
      onProgress: (progress) =>
          reply.send({'kind': 'progress', 'data': progress.toJson()}),
      onEvent: (event) => reply.send({'kind': 'event', 'data': event.toJson()}),
    );
    reply.send({'kind': 'result', 'data': result.toJson()});
    control.close();
  }
}
