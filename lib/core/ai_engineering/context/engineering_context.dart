import '../models/ai_engineering_models.dart';

class EngineeringContext {
  EngineeringContext({
    required this.projectId,
    required this.activePartId,
    List<String> surfaces = const [],
    List<String> patches = const [],
    List<String> boundaries = const [],
    List<String> references = const [],
    List<String> planes = const [],
    List<String> axes = const [],
    List<String> points = const [],
    List<String> operationHistory = const [],
    required this.workflow,
    required this.activeModule,
    Map<String, dynamic> manufacturingIntent = const {},
    Map<String, dynamic> userContext = const {},
    Map<String, dynamic> projectState = const {},
    Map<String, double> metrics = const {},
  }) : surfaces = List.unmodifiable(surfaces),
       patches = List.unmodifiable(patches),
       boundaries = List.unmodifiable(boundaries),
       references = List.unmodifiable(references),
       planes = List.unmodifiable(planes),
       axes = List.unmodifiable(axes),
       points = List.unmodifiable(points),
       operationHistory = List.unmodifiable(operationHistory),
       manufacturingIntent = Map.unmodifiable(manufacturingIntent),
       userContext = Map.unmodifiable(userContext),
       projectState = Map.unmodifiable(projectState),
       metrics = Map.unmodifiable(metrics);
  final String projectId, activePartId, workflow, activeModule;
  final List<String> surfaces,
      patches,
      boundaries,
      references,
      planes,
      axes,
      points,
      operationHistory;
  final Map<String, dynamic> manufacturingIntent, userContext, projectState;
  final Map<String, double> metrics;

  EngineeringContextSnapshot snapshot() => EngineeringContextSnapshot(
    projectId: projectId,
    activePartId: activePartId,
    values: {
      'surfaces': surfaces,
      'patches': patches,
      'boundaries': boundaries,
      'references': references,
      'planes': planes,
      'axes': axes,
      'points': points,
      'operationHistory': operationHistory,
      'workflow': workflow,
      'activeModule': activeModule,
      'manufacturingIntent': manufacturingIntent,
      'userContext': userContext,
      'projectState': projectState,
      'metrics': metrics,
    },
  );
}
