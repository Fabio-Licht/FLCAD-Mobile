import '../models/surface_morph_models.dart';

abstract interface class SurfaceMorphIntegration {
  void onMorphUpdated(MorphSession value);
}

class OfficialSurfaceMorphIntegration implements SurfaceMorphIntegration {
  OfficialSurfaceMorphIntegration({
    required this.project,
    required this.workflow,
    required this.session,
    required this.studio,
    required this.intelligence,
  });
  final Map<String, dynamic> project, workflow, session, studio, intelligence;
  @override
  void onMorphUpdated(MorphSession value) {
    final projection = value.toJson();
    project['surfaceMorph'] = projection;
    workflow['surfaceMorphStatus'] = value.status.name;
    session['surfaceMorph'] = projection;
    session['history'] = [
      ...(session['history'] as List? ?? const []),
      {'morph': value.id, 'status': value.status.name},
    ];
    studio['surfaceMorphStudio'] = true;
    studio['morphSession'] = projection;
    intelligence['morphAdvisor'] = value.advice.map((e) => e.toJson()).toList();
    intelligence['automaticActions'] = false;
  }
}
