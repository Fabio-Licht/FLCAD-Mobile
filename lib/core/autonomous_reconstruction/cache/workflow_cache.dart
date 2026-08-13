import '../models/reconstruction_models.dart';

class WorkflowCache {
  final Map<String, ReconstructionWorkflow> _values = {};
  ReconstructionWorkflow? get(String id) => _values[id];
  void put(ReconstructionWorkflow workflow) => _values[workflow.id] = workflow;
  void invalidate(String id) => _values.remove(id);
}
