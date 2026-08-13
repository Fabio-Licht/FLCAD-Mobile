import '../models/ai_context.dart';
import '../models/ai_result.dart';

abstract interface class AIProvider {
  String get id;
  Future<bool> isAvailable();
  Future<AIResult> execute(AIContext context);
}

class OnnxProvider implements AIProvider {
  @override
  String get id => 'onnx';
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<AIResult> execute(AIContext context) =>
      throw StateError('ONNX Runtime não está instalado');
}

class TensorFlowLiteProvider implements AIProvider {
  @override
  String get id => 'tensorflow_lite';
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<AIResult> execute(AIContext context) =>
      throw StateError('TensorFlow Lite não está instalado');
}

class CloudProvider implements AIProvider {
  @override
  String get id => 'cloud';
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<AIResult> execute(AIContext context) =>
      throw StateError('Cloud Provider não está configurado');
}

class MockProvider implements AIProvider {
  @override
  String get id => 'mock';
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<AIResult> execute(AIContext context) async => AIResult(
    pluginId: id,
    task: context.task.name,
    score: 80,
    confidence: .5,
    data: const {},
    recommendations: const [],
    createdAt: DateTime.now(),
  );
}
