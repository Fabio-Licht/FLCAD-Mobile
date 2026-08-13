import 'package:flutter/material.dart';

import '../../../core/ai/services/ai_bootstrap.dart';
import '../../projects/domain/project_manager.dart';
import '../../projects/models/project.dart';
import '../data/knowledge_repository.dart';
import '../models/advisor_recommendation.dart';

class IntelligentAssistantScreen extends StatefulWidget {
  const IntelligentAssistantScreen({super.key, required this.project});
  final Project project;
  @override
  State<IntelligentAssistantScreen> createState() =>
      _IntelligentAssistantScreenState();
}

class _IntelligentAssistantScreenState
    extends State<IntelligentAssistantScreen> {
  final KnowledgeRepository _knowledge = KnowledgeRepository();
  late Future<List<AdvisorRecommendation>> _recommendations;
  @override
  void initState() {
    super.initState();
    _recommendations = _knowledge.recommendations(widget.project.id);
  }

  @override
  Widget build(BuildContext context) {
    final current = ProjectManager.instance.current?.id == widget.project.id
        ? ProjectManager.instance.current!
        : widget.project;
    final stats = current.statistics;
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente Inteligente')),
      body: FutureBuilder<List<AdvisorRecommendation>>(
        future: _recommendations,
        builder: (context, snapshot) {
          final recommendations = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                current.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                children: [
                  _Indicator('Qualidade', stats.qualityScore),
                  _Indicator('Cobertura', stats.coverageScore),
                  _Indicator('Escala', stats.scaleScore),
                  _Indicator(
                    'Reconstrução',
                    stats.reconstructionProgress * 100,
                  ),
                  _Indicator('Confiança', stats.aiConfidence * 100),
                  _Indicator('Advisor', recommendations.isEmpty ? 100 : 70),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Problemas e sugestões',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (recommendations.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Nenhum problema registrado.'),
                    subtitle: Text(
                      'Continue capturando para receber análises.',
                    ),
                  ),
                ),
              for (final item in recommendations.reversed)
                Card(
                  child: ListTile(
                    leading: Icon(
                      item.severity == 'warning'
                          ? Icons.warning_amber
                          : Icons.lightbulb_outline,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.message),
                    trailing: Text(item.source),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Modelo ativo: ${AIBootstrap.instance.registry.installedModels.map((item) => '${item.name} ${item.version}').join(', ')}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${value.round()}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    ),
  );
}
