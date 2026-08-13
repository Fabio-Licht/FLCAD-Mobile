import '../recognizers/universal_recognizer.dart';

class RecognitionPluginRegistry {
  final Map<String, UniversalRecognizer> _recognizers = {};
  void register(UniversalRecognizer recognizer) {
    if (_recognizers.containsKey(recognizer.id)) {
      throw StateError('Recognizer ${recognizer.id} already registered');
    }
    _recognizers[recognizer.id] = recognizer;
  }

  UniversalRecognizer? remove(String id) => _recognizers.remove(id);
  List<UniversalRecognizer> get recognizers =>
      List.unmodifiable(_recognizers.values);
}
