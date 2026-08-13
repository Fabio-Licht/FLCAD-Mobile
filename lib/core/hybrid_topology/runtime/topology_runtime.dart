import '../../engineering/runtime/engineering_runtime.dart';
import '../../smart_regions/models/geometry.dart';
import '../constraints/topology_constraint.dart';
import '../morphing/mesh_morph_engine.dart';

class IsolateTopologyRuntime {
  const IsolateTopologyRuntime();
  Future<MorphResult> morph(
    MeshTopology mesh,
    MorphRequest request,
    List<TopologyConstraint> constraints,
  ) => EngineeringRuntime.shared
      .submit(
        'topology:${DateTime.now().microsecondsSinceEpoch}',
        () => const MeshMorphEngine().apply(mesh, request, constraints),
        namespace: 'topology',
      )
      .future;
}
