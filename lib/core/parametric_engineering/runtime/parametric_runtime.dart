import 'dart:isolate';
import '../features/engineering_feature.dart';
import '../kernel/geometry_kernel_adapter.dart';
import '../solids/engineering_solid.dart';

class IsolateParametricRuntime {
  const IsolateParametricRuntime();
  Future<SolidHandle> execute(
    GeometryKernelAdapter kernel,
    EngineeringFeature feature,
    List<SolidHandle> inputs,
  ) => Isolate.run(() => kernel.executeFeature(feature, inputs));
}
