import 'dart:isolate';
import '../../smart_regions/models/geometry.dart';
import '../constraints/topology_constraint.dart';
import '../morphing/mesh_morph_engine.dart';

class IsolateTopologyRuntime {
  const IsolateTopologyRuntime();
  Future<MorphResult> morph(
    MeshTopology mesh,
    MorphRequest request,
    List<TopologyConstraint> constraints,
  ) => Isolate.run(
    () => const MeshMorphEngine().apply(mesh, request, constraints),
  );
}
