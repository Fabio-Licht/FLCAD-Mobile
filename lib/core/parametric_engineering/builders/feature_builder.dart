import '../../utils/id_generator.dart';
import '../features/engineering_feature.dart';
import '../features/feature_dna.dart';

class FeatureRecipe {
  const FeatureRecipe({
    required this.projectId,
    required this.name,
    required this.kind,
    required this.sourceIds,
    this.dependencyIds = const [],
    this.referenceIds = const [],
    this.parameters = const {},
    this.intent = 'general',
    this.manufacturing = ManufacturingStrategy.unknown,
    this.inspection = InspectionStrategy.unknown,
    this.mode = FeatureMode.live,
  });
  final String projectId, name;
  final FeatureKind kind;
  final List<String> sourceIds, dependencyIds, referenceIds;
  final Map<String, dynamic> parameters;
  final String intent;
  final ManufacturingStrategy manufacturing;
  final InspectionStrategy inspection;
  final FeatureMode mode;
}

class FeatureBuilder {
  const FeatureBuilder();
  EngineeringFeature build(FeatureRecipe r) {
    final now = DateTime.now(),
        dna = createFeatureDNA(
          origins: r.sourceIds,
          intent: r.intent,
          parameters: r.parameters,
          manufacturing: r.manufacturing,
          inspection: r.inspection,
          relations: [...r.dependencyIds, ...r.referenceIds],
        );
    return EngineeringFeature(
      id: IdGenerator.generate(),
      projectId: r.projectId,
      name: r.name,
      kind: r.kind,
      mode: r.mode,
      status: FeatureStatus.pendingKernel,
      parameters: r.parameters,
      sourceIds: r.sourceIds,
      dependencyIds: r.dependencyIds,
      referenceIds: r.referenceIds,
      intent: r.intent,
      manufacturing: r.manufacturing,
      inspection: r.inspection,
      dna: dna,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
  }
}
