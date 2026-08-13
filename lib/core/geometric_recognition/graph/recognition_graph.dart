import '../../engineering/graph/engineering_graph.dart';
import '../models/recognition_models.dart';

class RecognitionGraph {
  RecognitionGraph({EngineeringGraph? engineeringGraph})
    : engineeringGraph = engineeringGraph ?? EngineeringGraph();
  final EngineeringGraph engineeringGraph;
  final Map<String, PrimitiveRecognitionResult> _results = {};
  void add(PrimitiveRecognitionResult result) {
    _results[result.id] = result;
    if (!engineeringGraph.nodes.containsKey(result.winner.regionId)) {
      engineeringGraph.addNode(
        EngineeringGraphNode(
          result.winner.regionId,
          EngineeringNodeType.region,
        ),
      );
    }
    engineeringGraph.addNode(
      EngineeringGraphNode(
        result.id,
        EngineeringNodeType.ai,
        metadata: {
          'domain': 'recognition',
          'primitive': result.winner.type.name,
          'confidence': result.dna.confidence,
        },
      ),
    );
    engineeringGraph.connect(
      EngineeringGraphEdge(result.winner.regionId, result.id, 'recognized-as'),
    );
  }

  PrimitiveRecognitionResult? find(String id) => _results[id];
  List<PrimitiveRecognitionResult> get values =>
      List.unmodifiable(_results.values);
}
