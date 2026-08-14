import 'dart:io';
import '../api/feature_modeling_api.dart';
import '../engine/feature_engine.dart';
import '../repository/feature_repository.dart';

class FeatureModelingFactory {
  const FeatureModelingFactory();
  FeatureModelingApi create({
    required Directory projectDirectory,
    required String projectId,
    FeatureExecutor? executor,
  }) => FeatureModelingApi(
    FeatureModelingEngine(
      projectId: projectId,
      repository: FeatureRepository(projectDirectory),
      executor: executor,
    ),
  );
}
