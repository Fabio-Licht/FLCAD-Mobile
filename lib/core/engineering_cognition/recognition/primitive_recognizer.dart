import '../../reverse_intelligence/features/probability_engines.dart';
import '../../reverse_intelligence/models/intelligence_models.dart';
import '../../smart_regions/models/smart_region.dart';
import '../models/cognition_models.dart';

class AutomaticPrimitiveRecognizer {
  const AutomaticPrimitiveRecognizer();
  List<PrimitiveRecognition> recognize(
    ReasoningSnapshot arei,
    List<SmartRegion> regions,
  ) {
    final global = const SurfaceProbabilityEngine().estimate(arei.observation),
        result = <PrimitiveRecognition>[];
    if (regions.isEmpty) {
      for (final score in global.where((p) => p.probability >= .25)) {
        result.add(
          PrimitiveRecognition(
            kind: score.label,
            confidence: score.probability,
            evidence: score.evidence
                .map(
                  (e) => CognitionEvidence(
                    e.id,
                    e.description,
                    e.value,
                    e.source,
                    reliability: e.reliability,
                  ),
                )
                .toList(),
            regionId: 'mesh:${arei.meshId}',
            provenance: 'AREI SurfaceProbabilityEngine',
            discardedAlternatives: global
                .where((x) => x.label != score.label)
                .map((x) => x.label)
                .take(3)
                .toList(),
          ),
        );
      }
      return result;
    }
    for (final region in regions) {
      final type = region.statistics.dominantType.toLowerCase(),
          curvature = region.statistics.averageCurvature.abs(),
          mapping = _normalize(type, curvature),
          geometry = type.contains('plane')
              ? (1 / (1 + curvature)).clamp(0, 1).toDouble()
              : (curvature / (1 + curvature)).clamp(0, 1).toDouble(),
          confidence = (region.confidence * .55 + geometry * .45)
              .clamp(0, 1)
              .toDouble(),
          evidence = [
            CognitionEvidence(
              '${region.id}:dominantType',
              'Region dominant type signal',
              1,
              'SmartRegions.RegionStatistics',
            ),
            CognitionEvidence(
              '${region.id}:curvature',
              'Region average curvature signal',
              geometry,
              'SmartRegions.RegionStatistics',
            ),
          ];
      result.add(
        PrimitiveRecognition(
          kind: mapping,
          confidence: confidence,
          evidence: evidence,
          regionId: region.id,
          provenance: 'Smart Regions + Geometric observation',
          discardedAlternatives: _alternatives(mapping),
        ),
      );
    }
    return result;
  }

  String _normalize(String value, double curvature) {
    if (value.contains('plane')) return 'plane';
    if (value.contains('cyl')) return 'cylinder';
    if (value.contains('cone')) return 'cone';
    if (value.contains('sphere')) return 'sphere';
    if (value.contains('tor')) return 'torus';
    return curvature < .01 ? 'plane' : 'patch';
  }

  List<String> _alternatives(String selected) => [
    'plane',
    'cylinder',
    'cone',
    'sphere',
    'torus',
    'revolution',
    'loft',
    'sweep',
    'patch',
  ].where((v) => v != selected).take(4).toList();
}
