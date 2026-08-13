import '../engines/ai_engine.dart';
import '../models/ai_model_metadata.dart';
import '../plugins/alpha_heuristic_plugin.dart';
import '../providers/ai_provider.dart';
import 'ai_capability_discovery.dart';
import 'ai_registry.dart';

class AIBootstrap {
  AIBootstrap._();
  static final AIBootstrap instance = AIBootstrap._();
  final AIEngine engine = AIEngine();
  final AIRegistry registry = AIRegistry();
  final providers = <AIProvider>[
    OnnxProvider(),
    TensorFlowLiteProvider(),
    CloudProvider(),
    MockProvider(),
  ];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final plugin = AlphaHeuristicPlugin();
    engine.plugins.register(plugin);
    for (final provider in providers) {
      engine.plugins.registerProvider(provider);
    }
    registry.register(
      AIModelMetadata(
        id: plugin.id,
        name: plugin.name,
        version: plugin.version,
        hash: 'builtin-alpha-1',
        author: 'FLCAD',
        releasedAt: DateTime.utc(2026, 8, 13),
        compatibility: const ['android', 'ios', 'windows', 'linux', 'macos'],
      ),
    );
    await const AICapabilityDiscovery().discover(providers);
    _initialized = true;
  }
}
