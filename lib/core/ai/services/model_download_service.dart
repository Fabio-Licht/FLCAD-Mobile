import '../models/ai_model_metadata.dart';

/// Download contract only. Network/model installation is intentionally outside M-004.
abstract interface class ModelDownloadService {
  Future<AIModelMetadata> download(Uri source);
  Future<void> cancel(String modelId);
}
