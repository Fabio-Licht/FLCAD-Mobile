import 'dart:io';

import '../api/smart_reference_api.dart';
import '../builder/reference_candidate_builder.dart';
import '../engine/smart_reference_engine.dart';
import '../ranking/reference_ranking_engine.dart';
import '../repository/smart_reference_repository.dart';
import 'smart_reference_integration.dart';

class SmartReferenceFactory {
  const SmartReferenceFactory();
  SmartReferenceApi create({
    required Directory projectDirectory,
    ReferenceRankingWeights? weights,
    SmartReferenceIntegration? integration,
  }) {
    final ranking = ReferenceRankingEngine(
      weights ?? ReferenceRankingWeights.equal,
    );
    return SmartReferenceApi(
      SmartReferenceEngine(
        repository: SmartReferenceRepository(projectDirectory),
        candidateBuilder: ReferenceCandidateBuilder(ranking: ranking),
        integration: integration,
      ),
    );
  }
}
