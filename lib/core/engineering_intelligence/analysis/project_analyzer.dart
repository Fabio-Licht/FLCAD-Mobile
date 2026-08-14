import '../models/intelligence_models.dart';

class ProjectAnalyzer {
  const ProjectAnalyzer();
  List<EngineeringDiagnostic> analyze(
    IntelligenceAnalysisType type,
    ProjectKnowledgeSnapshot snapshot,
    EngineeringScore score,
  ) => [
    if (snapshot.dependencyRisks > 0)
      EngineeringDiagnostic(
        analysisType: type,
        message: '${snapshot.dependencyRisks} fragile dependencies detected',
        severity: 'warning',
        affectedIds: const [],
      ),
    if (snapshot.criticalRegions.isNotEmpty)
      EngineeringDiagnostic(
        analysisType: type,
        message:
            '${snapshot.criticalRegions.length} critical regions require review',
        severity: 'critical',
        affectedIds: snapshot.criticalRegions,
      ),
    if (score.overall < 70)
      EngineeringDiagnostic(
        analysisType: type,
        message: 'Engineering score below target',
        severity: 'warning',
        affectedIds: const [],
      ),
    if (snapshot.features == 0)
      EngineeringDiagnostic(
        analysisType: type,
        message: 'No modeled features available',
        severity: 'information',
        affectedIds: const [],
      ),
  ];
}
