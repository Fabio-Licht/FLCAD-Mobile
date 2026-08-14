import '../../reverse_workflow/models/workflow_models.dart';
import '../models/adaptive_studio_models.dart';

class AdaptiveDashboard {
  const AdaptiveDashboard();
  void update(
    DashboardState dashboard,
    ReverseWorkflow workflow, {
    String recognition = 'idle',
    String alignment = 'idle',
    String validation = 'idle',
    String heatMap = 'idle',
    String? currentFeature,
    Iterable<String> timeline = const [],
    Iterable<String> checklist = const [],
  }) {
    dashboard
      ..workflow = workflow.name
      ..projectHealth = workflow.projectHealth
      ..engineeringScore = workflow.engineeringScore
      ..recognitionStatus = recognition
      ..alignmentStatus = alignment
      ..validationStatus = validation
      ..heatMapStatus = heatMap
      ..currentFeature = currentFeature
      ..progress = workflow.progress
      ..recommendations.clear()
      ..recommendations.addAll(workflow.recommendationIds)
      ..timeline.clear()
      ..timeline.addAll(timeline)
      ..checklist.clear()
      ..checklist.addAll(checklist);
  }
}
