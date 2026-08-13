import '../models/recognition_models.dart';

abstract interface class RecognitionPipelineStage<I, O> {
  String get name;
  Future<O> execute(RecognitionContext context, I input);
}

class RecognitionPipelineTrace {
  const RecognitionPipelineTrace(
    this.stage,
    this.startedAt,
    this.elapsed,
    this.success,
  );
  final String stage;
  final DateTime startedAt;
  final Duration elapsed;
  final bool success;
}

/// Names the replaceable URF sequence. Concrete algorithms are injected into
/// the engine; unsupported statistical methods remain explicit contracts.
class RecognitionPipeline {
  RecognitionPipeline(this.stages);
  final List<RecognitionPipelineStage<dynamic, dynamic>> stages;
  final List<RecognitionPipelineTrace> traces = [];
  Future<dynamic> run(RecognitionContext context, dynamic input) async {
    var value = input;
    for (final stage in stages) {
      final started = DateTime.now(), watch = Stopwatch()..start();
      try {
        value = await stage.execute(context, value);
        watch.stop();
        traces.add(
          RecognitionPipelineTrace(stage.name, started, watch.elapsed, true),
        );
      } catch (_) {
        watch.stop();
        traces.add(
          RecognitionPipelineTrace(stage.name, started, watch.elapsed, false),
        );
        rethrow;
      }
    }
    return value;
  }
}
