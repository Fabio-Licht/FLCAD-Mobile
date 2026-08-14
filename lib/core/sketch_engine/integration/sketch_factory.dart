import 'dart:io';

import '../analytics/sketch_analytics.dart';
import '../api/sketch_engine_api.dart';
import '../engine/sketch_engine.dart';
import '../history/sketch_history.dart';
import '../repository/sketch_repository.dart';
import '../runtime/sketch_runtime.dart';

class SketchEngineFactory {
  const SketchEngineFactory();
  SketchEngineApi create(Directory projectDirectory) => SketchEngineApi(
    SketchEngine(repository: SketchRepository(projectDirectory)),
  );
}

class SketchEngineServices {
  SketchEngineServices({
    SketchRuntime? runtime,
    SketchAnalytics? analytics,
    SketchHistory? history,
  }) : runtime = runtime ?? SketchRuntime(),
       analytics = analytics ?? SketchAnalytics(),
       history = history ?? SketchHistory();
  final SketchRuntime runtime;
  final SketchAnalytics analytics;
  final SketchHistory history;
}
