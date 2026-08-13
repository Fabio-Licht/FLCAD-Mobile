import '../../smart_regions/models/geometry.dart' as smart;
import '../geometry/primitives.dart';
import '../geometry/vectors.dart';

extension SmartVec3ToKernel on smart.Vec3 {
  Vector3 toKernel() => Vector3(x, y, z);
}

extension KernelVector3ToSmart on Vector3 {
  smart.Vec3 toSmart() => smart.Vec3(x, y, z);
}

extension SmartBoundingBoxToKernel on smart.BoundingBox {
  BoundingBox3 toKernel() => BoundingBox3(min.toKernel(), max.toKernel());
}

extension KernelBoundingBoxToSmart on BoundingBox3 {
  smart.BoundingBox toSmart() =>
      smart.BoundingBox(min.toSmart(), max.toSmart());
}
