import '../knowledge/knowledge_library.dart';
import '../reasoning/engineering_reasoner.dart';

class EngineeringAdvice {
  const EngineeringAdvice(
    this.title,
    this.explanation,
    this.confidence,
    this.relatedKnowledge,
  );
  final String title, explanation;
  final double confidence;
  final List<String> relatedKnowledge;
}

class EngineeringAdvisor {
  const EngineeringAdvisor();
  List<EngineeringAdvice> advise(
    EngineeringReasoningResult result,
    KnowledgeLibrary library,
  ) {
    return result.inferences.map((i) {
      final related = library
          .search(i.conclusion.split('.').last)
          .map((e) => e.id)
          .toList();
      return EngineeringAdvice(
        i.conclusion,
        i.explanation,
        i.confidence,
        related,
      );
    }).toList();
  }
}
