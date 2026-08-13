import 'package:flutter/material.dart';

import '../../../theme/flcad_colors.dart';
import '../../scanner/presentation/scanner_screen.dart';
import '../domain/project_manager.dart';
import '../models/project.dart';
import '../models/project_status.dart';
import '../models/project_summary.dart';
import '../widgets/create_project_dialog.dart';
import '../widgets/project_dashboard.dart';
import '../widgets/project_summary_card.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, this.manager});
  final ProjectManager? manager;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late final ProjectManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = widget.manager ?? ProjectManager.instance;
    _manager.addListener(_refresh);
    if (_manager.projects.isEmpty) _manager.initialize(restoreCurrent: false);
  }

  @override
  void dispose() {
    _manager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _open(Project project) async {
    final opened = await _manager.open(project);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScannerScreen(project: opened)),
    );
  }

  Future<void> _create() async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const CreateProjectDialog(),
    );
    if (values == null) return;
    final project = await _manager.create(
      name: values['name']!,
      client: values['client']!,
      description: values['description'] ?? '',
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScannerScreen(project: project)),
    );
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Projeto?'),
        content: const Text(
          'Todas as fotos e dados do projeto serão removidos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _manager.delete(project);
  }

  @override
  Widget build(BuildContext context) {
    final current = _manager.current;
    final projects = _manager.visibleProjects
        .where((project) => project.id != current?.id)
        .toList();
    return Scaffold(
      backgroundColor: FLCADColors.background,
      appBar: AppBar(
        title: current == null
            ? const Text('Meus Projetos')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Projeto Atual', style: TextStyle(fontSize: 11)),
                  Text(
                    '${current.name} • ${current.status.label}',
                    style: const TextStyle(fontSize: 17),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Novo Projeto'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            if (current != null) ...[
              ProjectSummaryCard(
                project: ProjectSummary.fromProject(current),
                isCurrent: true,
                onOpen: () => _open(current),
              ),
              const SizedBox(height: 16),
            ],
            ProjectDashboard(
              projects: _manager.totalProjects,
              photos: _manager.totalPhotos,
              reconstructions: _manager.totalReconstructions,
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: _manager.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Pesquisar por nome, cliente ou ID',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ProjectSort>(
                    initialValue: _manager.sort,
                    decoration: const InputDecoration(labelText: 'Ordenar'),
                    items: const [
                      DropdownMenuItem(
                        value: ProjectSort.mostRecent,
                        child: Text('Mais recente'),
                      ),
                      DropdownMenuItem(
                        value: ProjectSort.oldest,
                        child: Text('Mais antigo'),
                      ),
                      DropdownMenuItem(
                        value: ProjectSort.client,
                        child: Text('Cliente'),
                      ),
                      DropdownMenuItem(
                        value: ProjectSort.name,
                        child: Text('Nome'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) _manager.changeSort(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Arquivados'),
                  selected: _manager.showArchived,
                  onSelected: (_) => _manager.toggleArchived(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    _manager.showArchived
                        ? 'Nenhum projeto arquivado.'
                        : 'Nenhum projeto encontrado.',
                  ),
                ),
              ),
            for (final project in projects)
              ProjectSummaryCard(
                project: ProjectSummary.fromProject(project),
                onOpen: () => _open(project),
                onFavorite: () => _manager.toggleFavorite(project),
                onArchive: () => project.isArchived
                    ? _manager.restore(project)
                    : _manager.archive(project),
                onDelete: () => _confirmDelete(project),
              ),
          ],
        ),
      ),
    );
  }
}
