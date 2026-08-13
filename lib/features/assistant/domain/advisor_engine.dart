import '../../../core/ai/engines/ai_engine.dart';
import '../../../core/ai/models/ai_context.dart';
import '../../../core/ai/models/ai_result.dart';
import '../../../core/ai/models/ai_task.dart';
import '../../../core/utils/id_generator.dart';
import '../data/knowledge_repository.dart';
import '../models/advisor_recommendation.dart';

abstract class BaseAdvisor {
  const BaseAdvisor(this.engine, this.knowledge);
  final AIEngine engine;
  final KnowledgeRepository knowledge;
  AITask get task;
  String get source;

  Future<AIResult> analyze(AIContext context) async {
    final result = await engine.execute(context);
    await knowledge.record(
      context.projectId,
      type: source,
      data: result.toJson(),
    );
    if (!result.fromCache && engine.benchmark.metrics.isNotEmpty) {
      await knowledge.record(
        context.projectId,
        type: 'benchmark',
        data: engine.benchmark.metrics.last.toJson(),
      );
    }
    for (final message in result.recommendations) {
      await knowledge.addRecommendation(
        AdvisorRecommendation(
          id: IdGenerator.generate(),
          projectId: context.projectId,
          source: source,
          title: _title,
          message: message,
          severity: result.score < 60 ? 'warning' : 'info',
          createdAt: DateTime.now(),
          data: result.data,
        ),
      );
    }
    return result;
  }

  String get _title => switch (task) {
    AITask.captureQuality => 'Melhore esta captura',
    AITask.coverage => 'Cobertura incompleta',
    AITask.scale => 'Defina a escala',
    AITask.cleanup => 'Limpeza recomendada',
    AITask.reconstructionAdvice => 'Análise da reconstrução',
    _ => 'Recomendação do Assistente',
  };
}

class CaptureAdvisor extends BaseAdvisor {
  const CaptureAdvisor(super.engine, super.knowledge);
  @override
  AITask get task => AITask.captureQuality;
  @override
  String get source => 'capture';
}

class ScaleAdvisor extends BaseAdvisor {
  const ScaleAdvisor(super.engine, super.knowledge);
  @override
  AITask get task => AITask.scale;
  @override
  String get source => 'scale';
}

class CoverageAdvisor extends BaseAdvisor {
  const CoverageAdvisor(super.engine, super.knowledge);
  @override
  AITask get task => AITask.coverage;
  @override
  String get source => 'coverage';
}

class QualityAdvisor extends BaseAdvisor {
  const QualityAdvisor(super.engine, super.knowledge);
  @override
  AITask get task => AITask.generalQuality;
  @override
  String get source => 'quality';
}

class CleanupAdvisor extends BaseAdvisor {
  const CleanupAdvisor(super.engine, super.knowledge);
  @override
  AITask get task => AITask.cleanup;
  @override
  String get source => 'cleanup';
}

class ReconstructionAdvisor extends BaseAdvisor {
  const ReconstructionAdvisor(super.engine, super.knowledge);
  @override
  AITask get task => AITask.reconstructionAdvice;
  @override
  String get source => 'reconstruction';
}

class AdvisorEngine {
  factory AdvisorEngine({
    required AIEngine ai,
    KnowledgeRepository? knowledge,
  }) {
    final shared = knowledge ?? KnowledgeRepository();
    return AdvisorEngine._(
      shared,
      CaptureAdvisor(ai, shared),
      ScaleAdvisor(ai, shared),
      CoverageAdvisor(ai, shared),
      QualityAdvisor(ai, shared),
      CleanupAdvisor(ai, shared),
      ReconstructionAdvisor(ai, shared),
    );
  }
  const AdvisorEngine._(
    this.knowledge,
    this.capture,
    this.scale,
    this.coverage,
    this.quality,
    this.cleanup,
    this.reconstruction,
  );
  final KnowledgeRepository knowledge;
  final CaptureAdvisor capture;
  final ScaleAdvisor scale;
  final CoverageAdvisor coverage;
  final QualityAdvisor quality;
  final CleanupAdvisor cleanup;
  final ReconstructionAdvisor reconstruction;
}
