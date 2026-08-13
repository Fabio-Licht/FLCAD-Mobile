import 'package:flutter/material.dart';

import '../../projects/domain/project_manager.dart';
import '../../projects/models/project.dart';
import '../../projects/models/project_status.dart';
import '../../projects/screens/projects_screen.dart';
import '../../reconstruction/domain/reconstruction_manager.dart';
import '../../reconstruction/presentation/reconstruction_screen.dart';
import '../../assistant/presentation/intelligent_assistant_screen.dart';
import '../widgets/capture_view.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.project});
  final Project project;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ProjectManager _manager = ProjectManager.instance;
  final ReconstructionManager _reconstruction = ReconstructionManager.instance;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_refresh);
    _loadReconstruction();
  }

  @override
  void dispose() {
    _manager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadReconstruction() async {
    final job = await _reconstruction.load(widget.project.id);
    if (!mounted || job?.canResume != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final resume = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reconstrução interrompida'),
          content: const Text('Deseja continuar do último ponto válido?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Não'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (resume == true) {
        _reconstruction.resume();
      } else {
        await _reconstruction.discardInterrupted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = _manager.current?.id == widget.project.id
        ? _manager.current!
        : widget.project;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Projeto Atual', style: TextStyle(fontSize: 12)),
            Text(
              '${project.name} • ${project.status.label}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Assistente Inteligente',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IntelligentAssistantScreen(project: project),
              ),
            ),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Reconstrução',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReconstructionScreen(
                  project: project,
                  manager: _reconstruction,
                ),
              ),
            ),
            icon: const Icon(Icons.view_in_ar),
          ),
          IconButton(
            tooltip: 'Meus Projetos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectsScreen()),
            ),
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: CaptureView(project: project),
      ),
    );
  }
}
