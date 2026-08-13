import '../morphing/mesh_morph_engine.dart';

enum TopologyGPUBackend { cuda, metal, vulkan, openCl }

abstract interface class GPUTopologyProcessor {
  TopologyGPUBackend get backend;
  Future<MorphResult> morph(MorphRequest request);
}
