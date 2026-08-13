import '../../engineering/services/engineering_service_registry.dart';
import '../../reverse_intelligence/models/intelligence_models.dart';
import '../datasets/knowledge_dataset.dart';
import '../events/knowledge_events.dart';
import '../features/feature_library.dart';
import '../inspection/inspection_library.dart';
import '../knowledge/knowledge_library.dart';
import '../manufacturing/manufacturing_library.dart';
import '../materials/material_library.dart';
import '../models/knowledge_models.dart';
import '../ontology/engineering_ontology.dart';
import '../reasoning/engineering_reasoner.dart';
import '../standards/standards_registry.dart';

class EngineeringKnowledgeApi {
  EngineeringKnowledgeApi({
    EngineeringOntology? ontology,
    KnowledgeLibrary? library,
    EngineeringReasoner? reasoner,
    KnowledgeEventBus? events,
  }) : ontology = ontology ?? CoreEngineeringOntology.create(),
       library = library ?? _foundationLibrary(),
       reasoner = reasoner ?? EngineeringReasoner(),
       events = events ?? KnowledgeEventBus();
  final EngineeringOntology ontology;
  final KnowledgeLibrary library;
  final EngineeringReasoner reasoner;
  final KnowledgeEventBus events;
  final StandardsRegistry standards = StandardsRegistry.foundation();
  static KnowledgeLibrary _foundationLibrary() {
    final result = FeatureKnowledgeLibrary.create();
    result.merge(ManufacturingKnowledgeLibrary.create());
    result.merge(InspectionKnowledgeLibrary.create());
    result.merge(MaterialKnowledgeLibrary.create());
    return result;
  }

  List<KnowledgeConcept> query(String query) => library.search(query);
  KnowledgeConcept? explain(String id) => library.find(id) ?? ontology.find(id);
  EngineeringReasoningResult infer(EngineeringCase value) {
    final result = reasoner.reason(value);
    events.publish(
      KnowledgeEvent(
        'inferenceCompleted',
        value.entityId,
        DateTime.now().toUtc(),
        {'count': result.inferences.length},
      ),
    );
    return result;
  }

  EngineeringReasoningResult inferArei(
    ReasoningSnapshot snapshot, {
    Map<String, dynamic> observedFacts = const {},
  }) => infer(reasoner.fromArei(snapshot, observedFacts: observedFacts));
  void load(KnowledgeDataset dataset) {
    for (final concept in dataset.concepts) {
      library.register(concept);
    }
    events.publish(
      KnowledgeEvent('datasetLoaded', dataset.id, DateTime.now().toUtc(), {
        'version': dataset.version,
        'concepts': dataset.concepts.length,
      }),
    );
  }

  void install(EngineeringServiceRegistry services) =>
      services.register<EngineeringKnowledgeApi>(this);
}
