import 'dart:io';

import 'package:flcad_mobile/features/reconstruction/models/pipeline_event.dart';
import 'package:flcad_mobile/features/reconstruction/models/pipeline_progress.dart';
import 'package:flcad_mobile/features/reconstruction/pipeline/pipeline_context.dart';
import 'package:flcad_mobile/features/reconstruction/pipeline/pipeline_step.dart';
import 'package:flcad_mobile/features/reconstruction/pipeline/reconstruction_pipeline.dart';
import 'package:flcad_mobile/features/reconstruction/pipeline/standard_steps.dart';
import 'package:flcad_mobile/features/reconstruction/services/isolate_alpha_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late PipelineContext context;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('flcad_pipeline_');
    await Directory(
      '${root.path}/Reconstruction/Cache',
    ).create(recursive: true);
    await Directory('${root.path}/Mesh').create(recursive: true);
    final images = <String>[];
    for (var index = 0; index < 3; index++) {
      final file = File('${root.path}/image_$index.jpg');
      await file.writeAsBytes(List.filled(20 * 1024, index + 1));
      images.add(file.path);
    }
    context = PipelineContext(
      projectId: 'project-1',
      projectPath: root.path,
      imagePaths: images,
      fingerprint: 'fingerprint-1',
    );
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'standard pipeline completes with progress, events, report and model',
    () async {
      final progress = <PipelineProgress>[];
      final events = <PipelineEvent>[];
      final result =
          await ReconstructionPipeline(
            steps: createStandardPipelineSteps(),
          ).run(
            context,
            cancellation: PipelineCancellationToken(),
            onProgress: progress.add,
            onEvent: events.add,
          );

      expect(result.success, isTrue);
      expect(progress, hasLength(12));
      expect(progress.last.fraction, 1);
      expect(
        events.any((event) => event.type == PipelineEventType.pipelineStarted),
        isTrue,
      );
      expect(
        events.any((event) => event.type == PipelineEventType.pipelineFinished),
        isTrue,
      );
      expect(
        await File('${root.path}/Reconstruction/reconstruction.json').exists(),
        isTrue,
      );
      expect(await File(result.resultPath!).exists(), isTrue);
    },
  );

  test('cancellation stops safely between independent steps', () async {
    final token = PipelineCancellationToken();
    final second = _CountingStep('second');
    final result = await ReconstructionPipeline(
      steps: [_CancelStep(token), second],
    ).run(context, cancellation: token, onProgress: (_) {}, onEvent: (_) {});
    expect(result.cancelled, isTrue);
    expect(second.executions, 0);
  });

  test(
    'valid cache skips repeated work and reports cached progression',
    () async {
      final step = _CountingStep('cached');
      final pipeline = ReconstructionPipeline(steps: [step]);
      await pipeline.run(
        context,
        cancellation: PipelineCancellationToken(),
        onProgress: (_) {},
        onEvent: (_) {},
      );
      late PipelineProgress progress;
      final second = await pipeline.run(
        context,
        cancellation: PipelineCancellationToken(),
        onProgress: (value) => progress = value,
        onEvent: (_) {},
      );
      expect(second.success, isTrue);
      expect(step.executions, 1);
      expect(progress.fromCache, isTrue);
    },
  );

  test('step failures become failed results and events', () async {
    final events = <PipelineEvent>[];
    final result = await ReconstructionPipeline(steps: [_FailingStep()]).run(
      context,
      cancellation: PipelineCancellationToken(),
      onProgress: (_) {},
      onEvent: events.add,
    );
    expect(result.success, isFalse);
    expect(result.error, contains('PipelineException'));
    expect(
      events.any((event) => event.type == PipelineEventType.stepFailed),
      isTrue,
    );
  });

  test('alpha backend executes the pipeline in an isolate', () async {
    final backend = IsolateAlphaReconstructionBackend();
    final events = <PipelineEvent>[];
    final result = await backend.run(
      context,
      onProgress: (_) {},
      onEvent: events.add,
    );
    expect(result.success, isTrue);
    expect(events, isNotEmpty);
    await backend.dispose();
  });
}

class _CountingStep implements PipelineStep {
  _CountingStep(this.id);
  @override
  final String id;
  @override
  String get name => id;
  int executions = 0;
  @override
  Future<void> execute(PipelineContext context) async {
    executions++;
  }
}

class _CancelStep implements PipelineStep {
  _CancelStep(this.token);
  final PipelineCancellationToken token;
  @override
  String get id => 'cancel';
  @override
  String get name => 'Cancel';
  @override
  Future<void> execute(PipelineContext context) async => token.cancel();
}

class _FailingStep implements PipelineStep {
  @override
  String get id => 'failure';
  @override
  String get name => 'Failure';
  @override
  Future<void> execute(PipelineContext context) => throw StateError('expected');
}
