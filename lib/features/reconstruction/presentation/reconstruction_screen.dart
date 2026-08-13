import 'package:flutter/material.dart';

import '../../projects/models/project.dart';
import '../domain/reconstruction_manager.dart';
import '../models/pipeline_event.dart';
import '../models/reconstruction_status.dart';
import 'reconstruction_viewer_screen.dart';

class ReconstructionScreen extends StatefulWidget {
  const ReconstructionScreen({
    super.key,
    required this.project,
    required this.manager,
  });
  final Project project;
  final ReconstructionManager manager;

  @override
  State<ReconstructionScreen> createState() => _ReconstructionScreenState();
}

class _ReconstructionScreenState extends State<ReconstructionScreen> {
  @override
  void initState() {
    super.initState();
    widget.manager.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.manager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.manager.job;
    final running = widget.manager.isRunning;
    return Scaffold(
      appBar: AppBar(title: const Text('Reconstrução')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.project.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _status(job?.status),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: job?.progress ?? 0),
                  const SizedBox(height: 8),
                  Text(
                    '${((job?.progress ?? 0) * 100).round()}% • ${job?.currentStep ?? 'Pronto para iniciar'}',
                  ),
                  if (job?.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        job!.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!running)
            FilledButton.icon(
              onPressed: () => widget.manager.start(widget.project.id),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                job?.canResume == true
                    ? 'Continuar reconstrução'
                    : 'Iniciar reconstrução',
              ),
            ),
          if (running)
            FilledButton.tonalIcon(
              onPressed: widget.manager.cancel,
              icon: const Icon(Icons.stop),
              label: const Text('Cancelar com segurança'),
            ),
          if (job?.status == ReconstructionStatus.completed &&
              job?.resultPath != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReconstructionViewerScreen(modelPath: job!.resultPath!),
                ),
              ),
              icon: const Icon(Icons.view_in_ar),
              label: const Text('Abrir visualizador'),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Eventos do Pipeline',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final event
              in (job?.logs.reversed.take(50) ?? <PipelineEvent>[]))
            ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 8),
              title: Text(event.message),
              subtitle: Text(event.stepId ?? event.type.name),
            ),
        ],
      ),
    );
  }

  String _status(ReconstructionStatus? status) => switch (status) {
    null || ReconstructionStatus.created => 'Reconstrução não iniciada',
    ReconstructionStatus.waiting => 'Aguardando',
    ReconstructionStatus.running => 'Em andamento',
    ReconstructionStatus.paused => 'Pausada',
    ReconstructionStatus.cancelled => 'Cancelada',
    ReconstructionStatus.completed => 'Concluída',
    ReconstructionStatus.failed => 'Falhou',
  };
}
