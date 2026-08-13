import '../commands/engineering_command_bus.dart';
import '../events/engineering_event_bus.dart';
import '../knowledge/engineering_knowledge_bus.dart';
import '../queries/engineering_query_bus.dart';

class EngineeringPlatformBus {
  EngineeringPlatformBus({
    EngineeringEventBus? events,
    EngineeringCommandBus? commands,
    EngineeringQueryBus? queries,
    EngineeringKnowledgeBus? knowledge,
  }) : events = events ?? EngineeringEventBus(),
       commands = commands ?? EngineeringCommandBus(events: events),
       queries = queries ?? EngineeringQueryBus(),
       knowledge = knowledge ?? EngineeringKnowledgeBus();
  final EngineeringEventBus events;
  final EngineeringCommandBus commands;
  final EngineeringQueryBus queries;
  final EngineeringKnowledgeBus knowledge;
}
