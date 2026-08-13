# Feature Analytics

All operations run through `FeatureRuntime`, backed by Kernel Runtime and Engineering Runtime. Metrics include operation identity, elapsed time, success, entity count and rebuild activity.

Native kernel calls remain on the main runtime queue because native handles cannot cross Dart isolates safely.

