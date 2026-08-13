import '../models/kernel_models.dart';

enum GeometryValidationCheck {
  manifold,
  orientation,
  degeneration,
  closure,
  continuity,
  openWire,
  selfIntersection,
  duplicatedEdge,
  nonManifold,
  invalidShell,
  invalidSolid,
  tinyEdge,
  degeneratedFace,
  inconsistentOrientation,
}

abstract interface class GeometryValidatorContract {
  Future<List<String>> validate(
    ShapeHandle shape,
    Set<GeometryValidationCheck> checks,
  );
}

abstract interface class GeometryHealingContract {
  Future<ShapeHandle> heal(ShapeHandle shape, KernelTransaction transaction);
}

abstract interface class GeometrySewingContract {
  Future<ShapeHandle> sew(
    List<ShapeHandle> faces,
    KernelTransaction transaction,
  );
}

abstract interface class GeometryRepairContract {
  Future<ShapeHandle> repair(
    ShapeHandle shape,
    Set<String> fixes,
    KernelTransaction transaction,
  );
}
