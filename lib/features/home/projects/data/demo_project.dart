import '../../../../models/project.dart';

final demoProject = Project(
  id: 'demo',
  name: 'Nenhum projeto aberto',
  client: 'FLCAD Platform',
  description: 'Crie um projeto para iniciar um escaneamento.',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  status: ProjectStatus.created,
);
