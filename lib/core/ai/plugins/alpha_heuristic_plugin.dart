import 'dart:io';
import 'dart:isolate';

import '../models/ai_context.dart';
import '../models/ai_result.dart';
import '../models/ai_task.dart';
import 'ai_plugin.dart';

class AlphaHeuristicPlugin extends AIPlugin {
  @override
  String get id => 'flcad.alpha.heuristic';
  @override
  String get name => 'FLCAD Alpha Heuristics';
  @override
  String get version => '1.0.0';
  @override
  int get priority => 10;
  @override
  bool supports(AITask task) => true;

  @override
  Future<AIResult> execute(AIContext context) async {
    final input = <String, dynamic>{...context.input};
    final imagePath = input['imagePath'] as String?;
    if (imagePath != null && await File(imagePath).exists()) {
      final file = File(imagePath);
      input['fileSize'] = await file.length();
      input['sample'] = await file
          .openRead(0, 4096)
          .fold<List<int>>([], (bytes, chunk) => bytes..addAll(chunk));
    }
    final data = await Isolate.run(
      () => _infer({'task': context.task.name, 'input': input}),
    );
    return AIResult.fromJson(data);
  }

  static Map<String, dynamic> _infer(Map<String, dynamic> request) {
    final task = request['task'] as String;
    final input = (request['input'] as Map).cast<String, dynamic>();
    var score = 80.0;
    var confidence = .62;
    final recommendations = <String>[];
    final output = <String, dynamic>{};
    if (task == AITask.captureQuality.name) {
      final size = input['fileSize'] as int? ?? 0;
      final sample = (input['sample'] as List?)?.cast<int>() ?? const [];
      final mean = sample.isEmpty
          ? 128.0
          : sample.reduce((a, b) => a + b) / sample.length;
      final variance = sample.isEmpty
          ? 0.0
          : sample
                    .map((value) => (value - mean) * (value - mean))
                    .reduce((a, b) => a + b) /
                sample.length;
      score = 100;
      if (size < 16 * 1024) {
        score -= 30;
        recommendations.add('Aproxime-se e capture em maior resolução.');
      }
      if (mean < 45) {
        score -= 20;
        recommendations.add('Aumente a iluminação da peça.');
        output['exposure'] = 'dark';
      }
      if (mean > 215) {
        score -= 20;
        recommendations.add('Reduza a exposição ou reflexos.');
        output['exposure'] = 'bright';
      }
      if (variance < 250) {
        score -= 18;
        recommendations.add(
          'Reposicione a câmera para melhorar nitidez e contraste.',
        );
      }
      output.addAll({
        'sharpness': variance.clamp(0, 1000) / 10,
        'contrast': variance.clamp(0, 1000) / 10,
        'noise': 0,
        'motion': variance < 150 ? 'possible' : 'low',
        'resolutionBytes': size,
        'duplicate': false,
        'distance': 'unknown',
        'tilt': 'unknown',
      });
      confidence = .68;
    } else if (task == AITask.coverage.name) {
      final count = input['photoCount'] as int? ?? 0;
      score = (count * 2.5).clamp(0, 92);
      output['regions'] = count < 20
          ? ['parte inferior', 'região traseira', 'detalhes internos']
          : count < 40
          ? ['parte inferior']
          : <String>[];
      if ((output['regions'] as List).isNotEmpty) {
        recommendations.add('Capture as regiões indicadas por novos ângulos.');
      }
    } else if (task == AITask.scale.name) {
      score = input['method'] == null || input['method'] == 'later' ? 25 : 85;
      if (score < 50) {
        recommendations.add(
          'Defina uma referência de escala antes da etapa CAD.',
        );
      }
      output['method'] = input['method'] ?? 'later';
    } else if (task == AITask.segmentation.name) {
      output['maskType'] = 'alpha_simple';
      output['classes'] = ['piece', 'background'];
      confidence = .45;
    } else if (task == AITask.cleanup.name) {
      output['operations'] = [
        'isolated_points',
        'small_islands',
        'residual_background',
      ];
      score = 75;
    } else if (task == AITask.reconstructionAdvice.name) {
      score = (input['qualityScore'] as num? ?? 70).toDouble();
      output.addAll({
        'estimatedAccuracy': 'alpha',
        'coverage': input['coverage'] ?? 0,
        'photosUsed': input['photosUsed'] ?? 0,
        'photosDiscarded': input['photosDiscarded'] ?? 0,
      });
    }
    return AIResult(
      pluginId: 'flcad.alpha.heuristic',
      task: task,
      score: score.clamp(0, 100),
      confidence: confidence,
      data: output,
      recommendations: recommendations,
      createdAt: DateTime.now(),
    ).toJson();
  }
}
