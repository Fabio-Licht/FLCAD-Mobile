import '../../engineering/services/engineering_service_registry.dart';
import '../../smart_regions/models/geometry.dart';
import '../brain/reverse_brain.dart';
import '../memory/engineering_memory.dart';
import '../orchestrator/reconstruction_orchestrator.dart';

class ReverseIntelligenceApi {
  ReverseIntelligenceApi({
    ReconstructionOrchestrator? orchestrator,
    EngineeringMemory? memory,
  }) : orchestrator = orchestrator ?? ReconstructionOrchestrator(),
       memory = memory ?? InMemoryEngineeringMemory();
  final ReconstructionOrchestrator orchestrator;
  final EngineeringMemory memory;
  Future<ReverseBrainResult> analyze(String projectId, MeshTopology mesh) =>
      orchestrator.analyze(projectId, mesh);
  void install(EngineeringServiceRegistry services) =>
      services.register<ReverseIntelligenceApi>(this);
}
