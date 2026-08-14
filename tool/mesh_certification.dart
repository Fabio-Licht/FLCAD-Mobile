import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_factory.dart';
import 'package:flcad_mobile/core/mesh_foundation/integration/mesh_integration.dart';
import 'package:flcad_mobile/core/platform_certification/engine/platform_certification_engine.dart';
import 'package:flcad_mobile/core/platform_certification/repository/platform_certification_repository.dart';
import 'package:flcad_mobile/core/reverse_session/api/reverse_session_api.dart';
import 'package:flcad_mobile/core/reverse_session/engine/reverse_session_engine.dart';
import 'package:flcad_mobile/core/reverse_session/repository/reverse_session_repository.dart';
import 'package:flcad_mobile/core/reverse_session/models/session_models.dart';
import 'package:flcad_mobile/core/reverse_workflow/api/reverse_workflow_api.dart';
import 'package:flcad_mobile/core/reverse_workflow/engine/reverse_workflow_engine.dart';
import 'package:flcad_mobile/core/reverse_workflow/repository/workflow_repository.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/mesh_certification.dart <dll> <bearing.stl> <project-dir> [cycles]',
    );
    exitCode = 64;
    return;
  }
  final dll = args[0], stl = args[1], project = Directory(args[2]);
  final cycles = args.length > 3 ? int.parse(args[3]) : 100;
  await project.create(recursive: true);
  final kernel = OpenCascadeKernelAdapter(
    bridge: OpenCascadeFFI.load(path: dll),
  );
  final health = await kernel.healthCheck();
  if (health.status.name != 'healthy') throw StateError(health.message);
  final workflows = ReverseWorkflowApi(
        ReverseWorkflowEngine(repository: WorkflowRepository(project)),
      ),
      workflow = workflows.create('g010a-bearing', 'Bearing reverse workflow');
  workflows.open(workflow.id);
  final sessions = ReverseSessionApi(
        ReverseSessionEngine(repository: ReverseSessionRepository(project)),
      ),
      session = sessions.create(
        name: 'G-010A bearing',
        user: 'certification',
        context: SessionContext(projectId: 'g010a-bearing'),
      );
  sessions.open(session.id);
  final projectState = <String, dynamic>{}, dashboard = <String, dynamic>{};
  final integration = OfficialMeshIntegration(
    workflows: workflows,
    workflowId: workflow.id,
    sessions: sessions,
    sessionId: session.id,
    project: projectState,
    dashboard: dashboard,
  );
  final api = const MeshFactory().create(
    projectDirectory: project,
    kernel: kernel,
    integration: integration,
  );
  final first = await api.importStl(stl, projectId: 'g010a-bearing');
  final loadApi = const MeshFactory().create(
    projectDirectory: project,
    kernel: kernel,
  );
  for (var i = 1; i < cycles; i++) {
    final result = await loadApi.importStl(stl, projectId: 'g010a-bearing');
    await loadApi.close(result.mesh.id);
  }
  for (var i = 0; i < cycles; i++) {
    final imported = await loadApi.importStl(stl, projectId: 'g010a-bearing');
    final reloaded = await loadApi.reload(imported.mesh.id);
    await loadApi.close(reloaded.mesh.id);
  }
  await api.persist();
  await loadApi.persist();
  await workflows.engine.persist();
  await sessions.persist();
  final certification =
      PlatformCertificationEngine(
        repository: PlatformCertificationRepository(project),
      ).certifyMeshFoundation(
        mesh: first.mesh,
        project: projectState,
        workflow: workflow.toJson(),
        session: session.context.state,
        dashboard: dashboard,
      );
  for (final check in certification) {
    stdout.writeln('${check.name}: ${check.status.name} — ${check.evidence}');
  }
  if (certification.any((e) => e.status.name != 'passed')) {
    throw StateError('Mesh foundation certification failed');
  }
  stdout.writeln('Mesh: ${first.mesh.toJson()}');
  stdout.writeln('Analytics: ${loadApi.engine.analytics.toJson()}');
  await api.close(first.mesh.id);
  await kernel.unload();
}
