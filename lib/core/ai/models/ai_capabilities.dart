class AICapabilities {
  const AICapabilities({
    required this.cpuCores,
    required this.gpuAvailable,
    required this.npuAvailable,
    required this.onnxAvailable,
    required this.tensorFlowLiteAvailable,
    required this.cloudAvailable,
    this.estimatedRamBytes,
  });
  final int cpuCores;
  final bool gpuAvailable;
  final bool npuAvailable;
  final bool onnxAvailable;
  final bool tensorFlowLiteAvailable;
  final bool cloudAvailable;
  final int? estimatedRamBytes;
}
