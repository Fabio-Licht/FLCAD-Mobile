class FELRemoteRequest {
  const FELRemoteRequest({
    required this.projectId,
    required this.source,
    required this.requestId,
  });
  final String projectId, source, requestId;
  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'source': source,
    'requestId': requestId,
  };
}

class FELRemoteResult {
  const FELRemoteResult({
    required this.requestId,
    required this.state,
    required this.output,
    this.error,
  });
  final String requestId, state;
  final Map<String, dynamic> output;
  final String? error;
}

abstract interface class RemoteFELExecutor {
  Future<FELRemoteResult> execute(FELRemoteRequest request);
  Future<void> cancel(String requestId);
}
