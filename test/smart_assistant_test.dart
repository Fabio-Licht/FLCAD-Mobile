import 'dart:io';

import 'package:flcad_mobile/core/ai/engines/ai_engine.dart';
import 'package:flcad_mobile/core/ai/models/ai_context.dart';
import 'package:flcad_mobile/core/ai/models/ai_task.dart';
import 'package:flcad_mobile/core/ai/plugins/alpha_heuristic_plugin.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/assistant/data/knowledge_repository.dart';
import 'package:flcad_mobile/features/assistant/domain/advisor_engine.dart';
import 'package:flcad_mobile/features/assistant/domain/measurement_advisor.dart';
import 'package:flcad_mobile/features/assistant/domain/quality_engine.dart';
import 'package:flcad_mobile/features/assistant/domain/segmentation_cleanup_engines.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'capture advisor persists recommendations, knowledge and benchmark',
    () async {
      final root = await Directory.systemTemp.createTemp('flcad_advisor_');
      addTearDown(() => root.delete(recursive: true));
      final projects = ProjectRepository(
        storage: LocalStorageService(rootDirectory: root),
      );
      final project = await projects.create(name: 'Peça', client: 'Cliente');
      final directory = await projects.directoryFor(project.id);
      final image = File('${directory.path}/Images/test.jpg');
      await image.writeAsBytes(List.filled(100, 1));
      final ai = AIEngine()..plugins.register(AlphaHeuristicPlugin());
      final knowledge = KnowledgeRepository(projects: projects);
      final advisors = AdvisorEngine(ai: ai, knowledge: knowledge);
      final result = await advisors.capture.analyze(
        AIContext(
          projectId: project.id,
          projectPath: directory.path,
          task: AITask.captureQuality,
          input: {'imagePath': image.path},
          fingerprint: 'image-v1',
        ),
      );
      expect(result.score, lessThan(100));
      expect(await knowledge.recommendations(project.id), isNotEmpty);
      expect(
        await File('${directory.path}/AI/knowledge.json').exists(),
        isTrue,
      );
    },
  );

  test(
    'quality, measurement, segmentation and cleanup foundations work',
    () async {
      final quality = const QualityEngine().calculate(
        photoQuality: 90,
        coverage: 80,
        scale: 70,
        reconstruction: 60,
        mesh: 50,
        confidence: .8,
      );
      expect(quality.overall, closeTo(74.5, .01));
      final measurements = const MeasurementAdvisor().decide(
        scaleMethod: 'measurements',
        confidence: .5,
        coverage: 40,
      );
      expect(measurements, hasLength(3));

      final root = await Directory.systemTemp.createTemp('flcad_segmentation_');
      addTearDown(() => root.delete(recursive: true));
      final ai = AIEngine()..plugins.register(AlphaHeuristicPlugin());
      final context = AIContext(
        projectId: 'p',
        projectPath: root.path,
        task: AITask.segmentation,
        input: const {},
        fingerprint: 'mesh-v1',
      );
      final segmentation = await SmartSegmentationEngine(
        ai,
      ).createAlphaMask(context);
      final cleanup = await SmartCleanupEngine(ai).recommend(context);
      expect(segmentation.data['maskType'], 'alpha_simple');
      expect(cleanup.data['operations'], isNotEmpty);
      expect(Directory('${root.path}/AI/Segmentation').listSync(), isNotEmpty);
    },
  );
}
