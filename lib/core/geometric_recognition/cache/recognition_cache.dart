import '../../engineering/cache/engineering_cache.dart';
import '../models/recognition_models.dart';

class RecognitionCache {
  RecognitionCache({EngineeringCache? cache})
    : _cache = cache ?? EngineeringCache();
  final EngineeringCache _cache;
  String key(RecognitionContext context) =>
      '${context.observation.meshFingerprint}:'
      '${context.observation.regionFingerprint}:${_parameters(context.parameters)}';
  PrimitiveRecognitionResult? read(RecognitionContext context) =>
      _cache.get<PrimitiveRecognitionResult>(
        'geometry',
        key(context),
        fingerprint: context.observation.regionFingerprint,
        version: 1,
      );
  void write(RecognitionContext context, PrimitiveRecognitionResult result) =>
      _cache.put(
        'geometry',
        key(context),
        result,
        fingerprint: context.observation.regionFingerprint,
        version: 1,
      );
  void clear() => _cache.invalidateNamespace('geometry');
  String _parameters(Map<String, double> values) {
    final keys = values.keys.toList()..sort();
    return keys.map((key) => '$key=${values[key]}').join(';');
  }
}
