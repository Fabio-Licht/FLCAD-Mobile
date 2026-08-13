import 'dart:io';

import '../models/ai_capabilities.dart';
import '../providers/ai_provider.dart';

class AICapabilityDiscovery {
  const AICapabilityDiscovery();
  Future<AICapabilities> discover(List<AIProvider> providers) async {
    Future<bool> available(String id) async {
      final matching = providers.where((provider) => provider.id == id);
      return matching.isNotEmpty && await matching.first.isAvailable();
    }

    return AICapabilities(
      cpuCores: Platform.numberOfProcessors,
      gpuAvailable: false,
      npuAvailable: false,
      onnxAvailable: await available('onnx'),
      tensorFlowLiteAvailable: await available('tensorflow_lite'),
      cloudAvailable: await available('cloud'),
      estimatedRamBytes: ProcessInfo.currentRss,
    );
  }
}
