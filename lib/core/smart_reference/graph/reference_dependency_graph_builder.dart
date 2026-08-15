import '../models/smart_reference_models.dart';

class ReferenceDependencyGraphBuilder {
  const ReferenceDependencyGraphBuilder();
  ReferenceDependencyGraph build(List<ReferenceCandidate> candidates) {
    final ordered = [...candidates]
      ..sort((a, b) {
        final category = a.category.index.compareTo(b.category.index);
        return category != 0 ? category : a.id.compareTo(b.id);
      });
    final dependencies = <ReferenceDependency>[];
    for (var index = 1; index < ordered.length; index++) {
      dependencies.add(
        ReferenceDependency(
          from: ordered[index - 1].id,
          to: ordered[index].id,
          reason:
              'Canonical dependency order ${ordered[index - 1].category.name} to ${ordered[index].category.name}.',
        ),
      );
    }
    return ReferenceDependencyGraph(
      nodes: ordered.map((e) => e.id),
      dependencies: dependencies,
    );
  }
}
