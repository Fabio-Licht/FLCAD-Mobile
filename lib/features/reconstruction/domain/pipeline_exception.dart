class PipelineException implements Exception {
  const PipelineException(this.message, {this.stepId, this.cause});
  final String message;
  final String? stepId;
  final Object? cause;
  @override
  String toString() =>
      'PipelineException${stepId == null ? '' : '[$stepId]'}: $message';
}
