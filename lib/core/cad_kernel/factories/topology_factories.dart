import '../models/kernel_models.dart';

abstract interface class WireBuilder {
  Future<ShapeHandle> build(
    List<ShapeHandle> edges,
    KernelTransaction transaction,
  );
}

abstract interface class FaceBuilder {
  Future<ShapeHandle> build(ShapeHandle wire, KernelTransaction transaction);
}

abstract interface class ShellBuilder {
  Future<ShapeHandle> build(
    List<ShapeHandle> faces,
    KernelTransaction transaction,
  );
}

abstract interface class SolidBuilder {
  Future<ShapeHandle> build(ShapeHandle shell, KernelTransaction transaction);
}
