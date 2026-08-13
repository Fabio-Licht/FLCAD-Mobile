import 'dart:convert';
import 'dart:io';

import '../domain/pipeline_exception.dart';
import '../models/pipeline_event.dart';
import '../models/pipeline_progress.dart';
import '../models/pipeline_result.dart';
import 'pipeline_context.dart';
import 'pipeline_logger.dart';
import 'pipeline_step.dart';

class ReconstructionPipeline {
  ReconstructionPipeline({required this.steps});
  final List<PipelineStep> steps;

  Future<PipelineResult> run(
    PipelineContext context, {
    required PipelineCancellationToken cancellation,
    required void Function(PipelineProgress) onProgress,
    required void Function(PipelineEvent) onEvent,
  }) async {
    final startedAt = DateTime.now();
    context.values['pipelineStartedAt'] = startedAt.toIso8601String();
    final completed = <String>[];
    final logger = PipelineLogger(onEvent);
    logger.event(PipelineEventType.pipelineStarted, 'Pipeline iniciado');
    try {
      for (var index = 0; index < steps.length; index++) {
        if (cancellation.isCancelled) {
          return PipelineResult(
            success: false,
            cancelled: true,
            startedAt: startedAt,
            endedAt: DateTime.now(),
            completedSteps: completed,
            resultPath: null,
          );
        }
        final step = steps[index];
        final watch = Stopwatch()..start();
        final marker = File('${context.cachePath}/${step.id}.json');
        final cached = await _isCached(marker, context.fingerprint);
        logger.event(
          PipelineEventType.stepStarted,
          '${step.name} iniciada',
          stepId: step.id,
        );
        try {
          if (!cached) {
            await step.execute(context);
            await marker.parent.create(recursive: true);
            await marker.writeAsString(
              jsonEncode({
                'fingerprint': context.fingerprint,
                'completedAt': DateTime.now().toIso8601String(),
              }),
              flush: true,
            );
          }
          completed.add(step.id);
          watch.stop();
          logger.event(
            PipelineEventType.stepFinished,
            cached
                ? '${step.name} reutilizada do cache'
                : '${step.name} concluída',
            stepId: step.id,
            duration: watch.elapsed,
          );
          onProgress(
            PipelineProgress(
              stepId: step.id,
              stepName: step.name,
              stepIndex: index + 1,
              totalSteps: steps.length,
              fraction: (index + 1) / steps.length,
              fromCache: cached,
            ),
          );
        } catch (error) {
          watch.stop();
          logger.event(
            PipelineEventType.stepFailed,
            '${step.name} falhou',
            stepId: step.id,
            duration: watch.elapsed,
            error: error,
          );
          throw PipelineException(
            'Falha ao executar ${step.name}',
            stepId: step.id,
            cause: error,
          );
        }
      }
      final resultPath = context.values['resultPath'] as String?;
      logger.event(PipelineEventType.pipelineFinished, 'Pipeline concluído');
      return PipelineResult(
        success: true,
        cancelled: false,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        completedSteps: completed,
        resultPath: resultPath,
      );
    } catch (error) {
      return PipelineResult(
        success: false,
        cancelled: false,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        completedSteps: completed,
        resultPath: null,
        error: error.toString(),
      );
    }
  }

  Future<bool> _isCached(File marker, String fingerprint) async {
    if (!await marker.exists()) return false;
    try {
      final data =
          jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
      return data['fingerprint'] == fingerprint;
    } catch (_) {
      return false;
    }
  }
}
