import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/professional_workflow/models/workflow_models.dart';
import '../../../core/professional_workflow/runtime/professional_workflow_controller.dart';
import '../../projects/models/project.dart';
import '../../scanner/presentation/scanner_screen.dart';

class ProfessionalWorkspaceScreen extends StatefulWidget {
  const ProfessionalWorkspaceScreen({
    super.key,
    required this.project,
    this.controller,
  });
  final Project project;
  final ProfessionalWorkflowController? controller;
  @override
  State<ProfessionalWorkspaceScreen> createState() =>
      _ProfessionalWorkspaceScreenState();
}

class _ProfessionalWorkspaceScreenState
    extends State<ProfessionalWorkspaceScreen> {
  late final ProfessionalWorkflowController _controller =
      widget.controller ??
      ProfessionalWorkflowController(projectId: widget.project.id);
  StreamSubscription<ProfessionalWorkflowState>? _subscription;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    _subscription = _controller.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _advanceFromKeyboard() {
    final recommendations = _controller.state.recommendations;
    if (recommendations.isEmpty) return;
    final recommendation = recommendations.first;
    if (recommendation.stage == ProfessionalWorkflowStage.importStl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Importe um STL real pelo Projeto antes de continuar.'),
        ),
      );
      return;
    }
    _controller.accept(recommendation);
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): _ConfirmWorkflowIntent(),
        SingleActivator(LogicalKeyboardKey.space): _ConfirmWorkflowIntent(),
        SingleActivator(LogicalKeyboardKey.tab): _NextWorkspacePanelIntent(),
      },
      child: Actions(
        actions: {
          _ConfirmWorkflowIntent: CallbackAction<_ConfirmWorkflowIntent>(
            onInvoke: (_) {
              _advanceFromKeyboard();
              return null;
            },
          ),
          _NextWorkspacePanelIntent: CallbackAction<_NextWorkspacePanelIntent>(
            onInvoke: (_) {
              setState(() => _page = (_page + 1) % 4);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FLCAD Professional',
                    style: TextStyle(fontSize: 11),
                  ),
                  Text(
                    widget.project.name,
                    style: const TextStyle(fontSize: 17),
                  ),
                ],
              ),
              actions: [
                _StatusBadge(
                  label: state.processing ? 'IA processando' : 'IA pronta',
                  active: state.processing,
                ),
              ],
            ),
            body: Column(
              children: [
                LinearProgressIndicator(value: state.progress, minHeight: 3),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 900) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 250,
                              child: _ProjectExplorer(
                                state: state,
                                onSelect: _controller.selectArtifact,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: _WorkflowCenter(
                                state: state,
                                controller: _controller,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: 300,
                              child: _PropertiesPanel(state: state),
                            ),
                          ],
                        );
                      }
                      return switch (_page) {
                        0 => _WorkflowCenter(
                          state: state,
                          controller: _controller,
                        ),
                        1 => _ProjectExplorer(
                          state: state,
                          onSelect: _controller.selectArtifact,
                        ),
                        2 => _InspectorPanel(state: state),
                        _ => _TimelinePanel(entries: state.timeline),
                      };
                    },
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _page,
              onDestinationSelected: (value) => setState(() => _page = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.account_tree),
                  label: 'Fluxo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_open),
                  label: 'Explorer',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check),
                  label: 'Inspeção',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'Timeline',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              tooltip: 'Capturar imagens do projeto',
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scanner'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScannerScreen(project: widget.project),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowCenter extends StatelessWidget {
  const _WorkflowCenter({required this.state, required this.controller});
  final ProfessionalWorkflowState state;
  final ProfessionalWorkflowController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _Dashboard(snapshot: state.dashboard),
      const SizedBox(height: 8),
      _ProductivityStrip(controller: controller),
      const SizedBox(height: 16),
      Text('Próxima ação', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      for (final recommendation in state.recommendations)
        _SmartCard(
          recommendation: recommendation,
          onAccept: () {
            if (recommendation.stage == ProfessionalWorkflowStage.importStl) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Selecione um STL pelo importador do Projeto. Nenhum arquivo foi simulado.',
                  ),
                ),
              );
              return;
            }
            controller.accept(recommendation);
          },
          onReject: () => controller.reject(recommendation),
        ),
      const SizedBox(height: 16),
      Text('Workflow', style: Theme.of(context).textTheme.titleLarge),
      for (final step in state.steps)
        ListTile(
          leading: Icon(switch (step.status) {
            ProfessionalStageStatus.completed => Icons.check_circle,
            ProfessionalStageStatus.active => Icons.play_circle,
            ProfessionalStageStatus.ready => Icons.radio_button_checked,
            ProfessionalStageStatus.failed => Icons.error,
            ProfessionalStageStatus.blocked => Icons.block,
            ProfessionalStageStatus.locked => Icons.lock,
          }),
          title: Text(step.title),
          subtitle: step.blockReason == null ? null : Text(step.blockReason!),
          trailing: Text('${(step.progress * 100).round()}%'),
        ),
      const SizedBox(height: 80),
    ],
  );
}

class _SmartCard extends StatelessWidget {
  const _SmartCard({
    required this.recommendation,
    required this.onAccept,
    required this.onReject,
  });
  final WorkflowRecommendation recommendation;
  final VoidCallback onAccept, onReject;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${(recommendation.decision.confidence * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 10),
          Text(recommendation.decision.why),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Por quê e alternativas?'),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Impacto: ${recommendation.decision.impact}'),
              ),
              for (final evidence in recommendation.decision.evidence)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.check, size: 18),
                  title: Text(evidence.description),
                  subtitle: Text(evidence.source),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Alternativas: ${recommendation.decision.alternatives.join(' • ')}',
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onReject, child: const Text('Adiar')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAccept,
                child: Text(recommendation.actionLabel),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ProjectExplorer extends StatelessWidget {
  const _ProjectExplorer({required this.state, required this.onSelect});
  final ProfessionalWorkflowState state;
  final ValueChanged<String?> onSelect;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      Text(
        'Explorer do Projeto',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      for (final kind in ProfessionalArtifactKind.values)
        if (state.artifacts.any((item) => item.kind == kind))
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(kind.name),
            children: [
              for (final artifact in state.artifacts.where(
                (a) => a.kind == kind,
              ))
                ListTile(
                  selected: artifact.id == state.selectedArtifactId,
                  title: Text(artifact.name),
                  onTap: () => onSelect(artifact.id),
                  leading: const Icon(Icons.account_tree, size: 18),
                ),
            ],
          ),
    ],
  );
}

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({required this.state});
  final ProfessionalWorkflowState state;
  @override
  Widget build(BuildContext context) {
    final item = state.selectedArtifact;
    if (item == null) return const Center(child: Text('Selecione um objeto'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Propriedades', style: Theme.of(context).textTheme.titleMedium),
        _Property('Nome', item.name),
        _Property('Origem', item.origin),
        _Property('DNA', item.dna),
        _Property('Confiança', '${(item.confidence * 100).round()}%'),
        _Property('Dependências', item.dependencies.join(', ')),
        _Property('Referências', item.referenceIds.join(', ')),
      ],
    );
  }
}

class _Property extends StatelessWidget {
  const _Property(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value.isEmpty ? 'Nenhuma' : value),
  );
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel({required this.state});
  final ProfessionalWorkflowState state;
  @override
  Widget build(BuildContext context) {
    final value = state.inspector;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Engineering Inspector',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        _Metric('Qualidade', value.meshQuality),
        _Metric('Normais', value.normalConsistency),
        _Metric('Cobertura', value.coverage),
        _Metric('Confiança', value.confidence),
        _Metric('Prontidão', value.reconstructionReadiness),
        ListTile(
          title: const Text('Regiões abertas'),
          trailing: Text('${value.openRegions}'),
        ),
        for (final note in value.notes)
          ListTile(leading: const Icon(Icons.info_outline), title: Text(note)),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: LinearProgressIndicator(value: value.clamp(0, 1)),
    trailing: Text('${(value * 100).round()}%'),
  );
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.entries});
  final List<EngineeringTimelineEntry> entries;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Engineering Timeline',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      for (final entry in entries)
        ListTile(
          leading: CircleAvatar(child: Text('${entry.sequence}')),
          title: Text(entry.title),
          subtitle: Text('${entry.description}\n${entry.timestamp.toLocal()}'),
          isThreeLine: true,
          trailing: entry.replayable ? const Icon(Icons.replay) : null,
        ),
    ],
  );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});
  final WorkflowDashboardSnapshot snapshot;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          _Stat('Progresso', '${(snapshot.progress * 100).round()}%'),
          _Stat('Cobertura', '${(snapshot.coverage * 100).round()}%'),
          _Stat('Regiões', '${snapshot.regionCount}'),
          _Stat('Hipóteses', '${snapshot.hypothesisCount}'),
          _Stat('IA', snapshot.aiStatus),
          _Stat('Estratégia', snapshot.strategy),
        ],
      ),
    ),
  );
}

class _ProductivityStrip extends StatelessWidget {
  const _ProductivityStrip({required this.controller});
  final ProfessionalWorkflowController controller;
  @override
  Widget build(BuildContext context) {
    final value = controller.session.analytics();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _Stat(
              'Tempo economizado',
              '${value.estimatedTimeSaved.inMinutes} min',
            ),
            _Stat('Operações evitadas', '${value.operationsAvoided}'),
            _Stat('Automações', '${value.automationsUsed}'),
            _Stat('Aceitação IA', '${(value.acceptanceRate * 100).round()}%'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 100,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, maxLines: 2),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.active});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Chip(
      avatar: Icon(active ? Icons.sync : Icons.check_circle, size: 16),
      label: Text(label),
    ),
  );
}

class _ConfirmWorkflowIntent extends Intent {
  const _ConfirmWorkflowIntent();
}

class _NextWorkspacePanelIntent extends Intent {
  const _NextWorkspacePanelIntent();
}
