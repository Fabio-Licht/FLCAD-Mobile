class RecognizedFeature {
  const RecognizedFeature(this.kind, this.sourceIds, this.confidence);
  final String kind;
  final List<String> sourceIds;
  final double confidence;
}

abstract interface class FeatureRecognizer {
  Future<List<RecognizedFeature>> recognize(
    String projectId,
    List<String> sourceIds,
  );
}
