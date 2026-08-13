import 'package:flutter/material.dart';

import '../../shared/widgets/dashboard_header.dart';
import '../../theme/flcad_colors.dart';
import '../projects/domain/project_manager.dart';
import '../projects/models/project.dart';
import '../projects/models/project_summary.dart';
import '../projects/screens/projects_screen.dart';
import '../projects/widgets/create_project_dialog.dart';
import '../projects/widgets/project_dashboard.dart';
import '../projects/widgets/project_summary_card.dart';
import '../scanner/presentation/scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectManager _manager = ProjectManager.instance;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final current = _manager.current;
    return Scaffold(
      backgroundColor: FLCADColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const DashboardHeader(),
            const SizedBox(height: 24),
            if (current != null) ...[
              ProjectSummaryCard(
                project: ProjectSummary.fromProject(current),
                isCurrent: true,
                onOpen: () => _open(current),
              ),
              const SizedBox(height: 20),
            ],
            ProjectDashboard(
              projects: _manager.totalProjects,
              photos: _manager.totalPhotos,
              reconstructions: _manager.totalReconstructions,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectsScreen()),
              ),
              icon: const Icon(Icons.folder_open),
              label: const Text('Meus Projetos'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Novo Projeto'),
            ),
          ],
        ),
      ),
    );
  }
}
