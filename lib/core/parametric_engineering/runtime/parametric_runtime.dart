import '../../engineering/runtime/engineering_runtime.dart';
import '../features/engineering_feature.dart';
import '../kernel/geometry_kernel_adapter.dart';
import '../solids/engineering_solid.dart';

class IsolateParametricRuntime {
  const IsolateParametricRuntime();
  Future<SolidHandle> execute(
    GeometryKernelAdapter kernel,
    EngineeringFeature feature,
    List<SolidHandle> inputs,
  ) => EngineeringRuntime.shared
      .submit(
        'parametric:${DateTime.now().microsecondsSinceEpoch}',
        () => kernel.executeFeature(feature, inputs),
        namespace: 'topology',
      )
      .future;
}
