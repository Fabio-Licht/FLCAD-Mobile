import '../models/live_reconstruction_models.dart';

class IncrementalScheduler {
  const IncrementalScheduler();
  List<String> schedule(AffectedObjects affected) => [
    ...affected.patches,
    ...affected.boundaries,
    ...affected.continuity,
    ...affected.reflection,
    ...affected.zebra,
    ...affected.draft,
    ...affected.heatMap,
    ...affected.validation,
    ...affected.analytics,
  ];
}
