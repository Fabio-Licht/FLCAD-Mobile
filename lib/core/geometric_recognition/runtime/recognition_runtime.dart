import '../../engineering/runtime/engineering_runtime.dart';

class RecognitionRuntime {
  const RecognitionRuntime();
  Future<T> run<T>(
    String id,
    T Function() operation, {
    void Function(double progress)? onProgress,
  }) => EngineeringRuntime.shared
      .submit(
        id,
        operation,
        namespace: 'geometry',
        priority: EngineeringTaskPriority.high,
        onProgress: (value) => onProgress?.call(value.value),
      )
      .future;
  bool cancel(String id) => EngineeringRuntime.shared.cancel(id);
  void pause() => EngineeringRuntime.shared.pause();
  void resume() => EngineeringRuntime.shared.resume();
}
