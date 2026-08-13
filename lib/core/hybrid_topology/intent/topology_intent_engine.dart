class TopologyIntent {
  const TopologyIntent(this.kind, this.preserveFeatures, this.confidence);
  final String kind;
  final bool preserveFeatures;
  final double confidence;
}

class TopologyIntentEngine {
  const TopologyIntentEngine();
  TopologyIntent infer(String operation, {String? manufacturing}) =>
      TopologyIntent(
        manufacturing == null ? operation : '$operation-for-$manufacturing',
        !{'cleaning', 'noise-removal'}.contains(operation),
        manufacturing == null ? .7 : 1.0,
      );
}
