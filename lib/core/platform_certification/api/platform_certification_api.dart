import '../engine/platform_certification_engine.dart';
import '../reports/certification_models.dart';
import '../../mesh_foundation/models/mesh_models.dart';

class PlatformCertificationApi {
  const PlatformCertificationApi(this.engine);
  final PlatformCertificationEngine engine;
  Future<DemonstrationResult> demonstrate({
    required String partPath,
    required Map<String, DemonstrationStep> steps,
  }) => engine.demonstrate(partPath: partPath, steps: steps);
  CertificationReport certify({
    required Map<String, String> evidence,
    DemonstrationResult? demonstration,
    EngineeringAudit? audit,
  }) => engine.certify(
    evidence: evidence,
    demonstration: demonstration,
    audit: audit,
  );
  Future<void> persist() => engine.persist();
  List<CertificationCheck> certifyMeshFoundation({
    required MeshEntity mesh,
    required Map<String, dynamic> project,
    required Map<String, dynamic> workflow,
    required Map<String, dynamic> session,
    required Map<String, dynamic> dashboard,
  }) => engine.certifyMeshFoundation(
    mesh: mesh,
    project: project,
    workflow: workflow,
    session: session,
    dashboard: dashboard,
  );
}
