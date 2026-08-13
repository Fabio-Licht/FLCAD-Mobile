import '../api/geometry_kernel_api.dart';
import '../ids/persistent_id_service.dart';
import '../models/kernel_models.dart';

abstract interface class GeometryFactory {
  CADShapeType get type;
  Future<ShapeHandle> create(
    Map<String, dynamic> parameters, {
    required String projectId,
    required KernelTransaction transaction,
  });
}

class KernelGeometryFactory implements GeometryFactory {
  const KernelGeometryFactory(this.type, this.operation, this.kernel, this.ids);
  @override
  final CADShapeType type;
  final String operation;
  final GeometryKernelAPI kernel;
  final PersistentIdService ids;
  @override
  Future<ShapeHandle> create(
    Map<String, dynamic> parameters, {
    required String projectId,
    required KernelTransaction transaction,
  }) => kernel.create(
    operation,
    parameters,
    persistentId: ids.create(projectId, type.name),
    expectedType: type,
    transaction: transaction,
  );
}

class GeometryFactories {
  GeometryFactories(
    GeometryKernelAPI kernel, {
    PersistentIdService ids = const PersistentIdService(),
  }) : vertex = KernelGeometryFactory(
         CADShapeType.vertex,
         'CREATE VERTEX',
         kernel,
         ids,
       ),
       edge = KernelGeometryFactory(
         CADShapeType.edge,
         'CREATE EDGE',
         kernel,
         ids,
       ),
       wire = KernelGeometryFactory(
         CADShapeType.wire,
         'CREATE WIRE',
         kernel,
         ids,
       ),
       face = KernelGeometryFactory(
         CADShapeType.face,
         'CREATE FACE',
         kernel,
         ids,
       ),
       shell = KernelGeometryFactory(
         CADShapeType.shell,
         'CREATE SHELL',
         kernel,
         ids,
       ),
       solid = KernelGeometryFactory(
         CADShapeType.solid,
         'CREATE SOLID',
         kernel,
         ids,
       ),
       compound = KernelGeometryFactory(
         CADShapeType.compound,
         'CREATE COMPOUND',
         kernel,
         ids,
       );
  final GeometryFactory vertex, edge, wire, face, shell, solid, compound;
}
