import '../../utils/id_generator.dart';

enum ProfileType {
  closed,
  open,
  nested,
  composite,
  chain,
  selfIntersecting,
  multiple,
  disconnected,
  invalid,
  tinyGap,
  tinyEdge,
  duplicatedEdge,
  overlappingEdge,
}

enum LoopType { outer, inner, hole, island, nested }

enum LoopOrientation { clockwise, counterClockwise, invalid }

enum RegionType {
  closed,
  open,
  island,
  hole,
  pocket,
  boss,
  boundary,
  sharedBoundary,
}

enum GeometricIntent {
  rectangle,
  slot,
  flange,
  rib,
  boss,
  pocket,
  holePattern,
  symmetry,
  repeatedGeometry,
  constructionPattern,
  referencePattern,
  baseSketch,
  auxiliarySketch,
  unknown,
}

enum ProfileVisualState {
  closedProfile,
  openProfile,
  region,
  hole,
  island,
  invalidRegion,
  tinyGap,
  conflict,
  selectedRegion,
  hoveredRegion,
}

class RecognizedProfile {
  RecognizedProfile({
    required this.type,
    required Iterable<String> entityIds,
    this.area = 0,
    this.perimeter = 0,
    this.confidence = 1,
    String? id,
    List<String>? diagnostics,
  }) : id = id ?? 'profile:${IdGenerator.generate()}',
       entityIds = entityIds.toList(),
       diagnostics = diagnostics ?? <String>[];
  final String id;
  ProfileType type;
  final List<String> entityIds;
  double area, perimeter, confidence;
  final List<String> diagnostics;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'entityIds': entityIds,
    'area': area,
    'perimeter': perimeter,
    'confidence': confidence,
    'diagnostics': diagnostics,
  };
}

class ProfileLoop {
  ProfileLoop({
    required this.profileId,
    required this.type,
    required this.entityIds,
    required this.orientation,
    this.area = 0,
    this.perimeter = 0,
    String? id,
    List<String>? diagnostics,
  }) : id = id ?? 'loop:${IdGenerator.generate()}',
       diagnostics = diagnostics ?? <String>[];
  final String id, profileId;
  LoopType type;
  final List<String> entityIds;
  LoopOrientation orientation;
  double area, perimeter;
  final List<String> diagnostics;
  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'type': type.name,
    'entityIds': entityIds,
    'orientation': orientation.name,
    'area': area,
    'perimeter': perimeter,
    'diagnostics': diagnostics,
  };
}

class SketchRegion {
  SketchRegion({
    required this.type,
    required Iterable<String> loopIds,
    this.priority = 0,
    String? id,
    String? parentId,
    Iterable<String> children = const [],
  }) : id = id ?? 'region:${IdGenerator.generate()}',
       loopIds = loopIds.toList(),
       parentId = parentId,
       children = children.toList();
  final String id;
  RegionType type;
  final List<String> loopIds;
  int priority;
  String? parentId;
  final List<String> children;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'loopIds': loopIds,
    'priority': priority,
    'parentId': parentId,
    'children': children,
  };
}

class IntentRecognition {
  const IntentRecognition(this.intent, this.confidence, this.evidence);
  final GeometricIntent intent;
  final double confidence;
  final List<String> evidence;
}

class FeatureReadiness {
  const FeatureReadiness({
    required this.extrude,
    required this.revolve,
    required this.sweep,
    required this.loft,
    required this.boolean,
    required this.shell,
    required this.draft,
    required this.fillet,
    required this.reasons,
  });
  final bool extrude, revolve, sweep, loft, boolean, shell, draft, fillet;
  final Map<String, String> reasons;
  Map<String, dynamic> toJson() => {
    'extrudeReady': extrude,
    'revolveReady': revolve,
    'sweepReady': sweep,
    'loftReady': loft,
    'booleanReady': boolean,
    'shellReady': shell,
    'draftReady': draft,
    'filletReady': fillet,
    'reasons': reasons,
  };
}

class ProfileQuality {
  const ProfileQuality(
    this.score,
    this.topology,
    this.profile,
    this.region,
    this.loop,
    this.manufacturability,
    this.featureReadiness,
    this.explanation,
  );
  final int score,
      topology,
      profile,
      region,
      loop,
      manufacturability,
      featureReadiness;
  final List<String> explanation;
}

class ProfileRecommendation {
  const ProfileRecommendation({
    required this.title,
    required this.confidence,
    required this.explanation,
    required this.impact,
    required this.alternatives,
    required this.pros,
    required this.cons,
    required this.suggestedAction,
  });
  final String title, explanation, impact, suggestedAction;
  final int confidence;
  final List<String> alternatives, pros, cons;
}
