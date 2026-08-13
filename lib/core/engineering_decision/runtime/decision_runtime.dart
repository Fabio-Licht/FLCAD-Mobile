import '../../engineering/runtime/engineering_runtime.dart';

class DecisionRuntime {
  const DecisionRuntime();
  EngineeringTask<T> schedule<T>(String id, Future<T> Function() operation) =>
      EngineeringRuntime.shared.submit(
        id,
        operation,
        namespace: 'cognition',
        priority: EngineeringTaskPriority.high,
      );
}
