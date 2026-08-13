import '../morphing/mesh_morph_engine.dart';

abstract interface class DistributedTopologyProcessor {
  Future<MorphResult> execute(String projectId, MorphRequest request);
  Future<void> cancel(String operationId);
}
