import '../models/profile_models.dart';
import '../validation/profile_validation.dart';

class ProfileQualityEvaluator {
  const ProfileQualityEvaluator();
  ProfileQuality evaluate(
    List<RecognizedProfile> profiles,
    List<ProfileLoop> loops,
    List<SketchRegion> regions,
    ProfileValidationResult validation,
  ) {
    final severe = validation.issues
            .where(
              (i) =>
                  i.type == ProfileIssueType.selfIntersection ||
                  i.type == ProfileIssueType.zeroArea,
            )
            .length,
        open = validation.issues
            .where(
              (i) =>
                  i.type == ProfileIssueType.openEnd ||
                  i.type == ProfileIssueType.brokenLoop,
            )
            .length,
        other = validation.issues.length - severe - open;
    final topology = (100 - severe * 25 - open * 10 - other * 5).clamp(0, 100),
        profile =
            (100 -
                    profiles
                            .where(
                              (p) =>
                                  p.type == ProfileType.invalid ||
                                  p.type == ProfileType.selfIntersecting,
                            )
                            .length *
                        20 -
                    open * 8)
                .clamp(0, 100),
        loop = (100 - loops.where((l) => l.orientation == LoopOrientation.invalid).length * 12).clamp(
          0,
          100,
        ),
        region =
            (100 - regions.where((r) => r.type == RegionType.open).length * 10)
                .clamp(0, 100),
        manufacturing = (topology * .6 + profile * .4).round(),
        readiness = (topology * .4 + profile * .3 + loop * .2 + region * .1)
            .round(),
        score =
            ((topology + profile + loop + region + manufacturing + readiness) / 6)
                .round();
    return ProfileQuality(
      score,
      topology,
      profile,
      region,
      loop,
      manufacturing,
      readiness,
      [
        '${validation.issues.length} validation issues',
        '${profiles.length} profiles, ${loops.length} loops, ${regions.length} regions',
      ],
    );
  }

  FeatureReadiness readiness(
    ProfileQuality q,
    List<RecognizedProfile> profiles,
  ) {
    final closed = profiles.any(
          (p) => p.type == ProfileType.closed || p.type == ProfileType.nested,
        ),
        open = profiles.any(
          (p) => p.type == ProfileType.open || p.type == ProfileType.chain,
        ),
        valid = q.topology >= 75;
    return FeatureReadiness(
      extrude: closed && valid,
      revolve: closed && valid,
      sweep: open && valid,
      loft: profiles.length >= 2 && valid,
      boolean: closed && valid,
      shell: closed && q.score >= 80,
      draft: closed && valid,
      fillet: valid,
      reasons: {
        'extrude': closed
            ? 'Closed profile available'
            : 'Requires a closed profile',
        'revolve': closed
            ? 'Closed section available'
            : 'Requires a closed section',
        'sweep': open ? 'Path candidate available' : 'Requires an open path',
        'loft': profiles.length >= 2
            ? 'Multiple sections available'
            : 'Requires multiple profiles',
      },
    );
  }
}
