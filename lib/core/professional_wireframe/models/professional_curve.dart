import '../../cad_kernel/models/kernel_models.dart';

enum ProfessionalCurveType {
  line3d,
  polyline3d,
  spline3d,
  composite,
  guide,
  section,
  projected,
  boundary,
  intersection,
  silhouette,
  center,
  iso,
}

enum CurveContinuity { g0, g1, g2 }

enum CurveAssociationState { current, outdated, detached }

class ProfessionalCurve {
  const ProfessionalCurve({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    required this.handle,
    required this.revision,
    required this.associationState,
    required this.createdAt,
    required this.updatedAt,
    this.sourceEntityId,
    this.continuity = CurveContinuity.g0,
    this.visible = true,
    this.locked = false,
    this.color = 'splineMagenta',
    this.metadata = const {},
  });

  final String id, name;
  final ProfessionalCurveType type;
  final List<List<double>> points;
  final ShapeHandle handle;
  final int revision;
  final String? sourceEntityId;
  final CurveContinuity continuity;
  final CurveAssociationState associationState;
  final bool visible, locked;
  final String color;
  final DateTime createdAt, updatedAt;
  final Map<String, dynamic> metadata;

  Future<CurveLocalProperties> propertiesAt(
    CurveGeometryEvaluator evaluator,
    double parameter,
  ) => evaluator.propertiesAt(this, parameter);

  Future<CurveClosestPoint> closestPoint(
    CurveGeometryEvaluator evaluator,
    List<double> point,
  ) => evaluator.closestPoint(this, point);

  Future<ProfessionalCurve> projectOntoSurface(
    CurveGeometryEvaluator evaluator,
    ShapeHandle surface,
  ) => evaluator.projectOntoSurface(this, surface);

  Future<ProfessionalCurve> projectOntoCurve(
    CurveGeometryEvaluator evaluator,
    ProfessionalCurve target,
  ) => evaluator.projectOntoCurve(this, target);

  Future<List<CurveIntersection>> intersectCurve(
    CurveGeometryEvaluator evaluator,
    ProfessionalCurve target,
  ) => evaluator.intersectCurve(this, target);

  Future<List<CurveIntersection>> intersectSurface(
    CurveGeometryEvaluator evaluator,
    ShapeHandle surface,
  ) => evaluator.intersectSurface(this, surface);

  Future<CurveContinuityReport> continuityWithCurve(
    CurveGeometryEvaluator evaluator,
    ProfessionalCurve target,
  ) => evaluator.continuityWithCurve(this, target);

  Future<CurveContinuityReport> tangencyWithSurface(
    CurveGeometryEvaluator evaluator,
    ShapeHandle surface,
  ) => evaluator.tangencyWithSurface(this, surface);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'points': points,
    'handle': handle.toJson(),
    'revision': revision,
    'sourceEntityId': sourceEntityId,
    'continuity': continuity.name,
    'associationState': associationState.name,
    'visible': visible,
    'locked': locked,
    'color': color,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'metadata': metadata,
  };

  factory ProfessionalCurve.fromJson(Map<String, dynamic> json) =>
      ProfessionalCurve(
        id: json['id'] as String,
        name: json['name'] as String,
        type: ProfessionalCurveType.values.byName(json['type'] as String),
        points: (json['points'] as List)
            .map(
              (point) =>
                  (point as List).cast<num>().map((v) => v.toDouble()).toList(),
            )
            .toList(),
        handle: ShapeHandle.fromJson(
          Map<String, dynamic>.from(json['handle'] as Map),
        ),
        revision: json['revision'] as int,
        sourceEntityId: json['sourceEntityId'] as String?,
        continuity: CurveContinuity.values.byName(
          json['continuity'] as String? ?? 'g0',
        ),
        associationState: CurveAssociationState.values.byName(
          json['associationState'] as String? ?? 'detached',
        ),
        visible: json['visible'] as bool? ?? true,
        locked: json['locked'] as bool? ?? false,
        color: json['color'] as String? ?? 'splineMagenta',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        metadata: Map<String, dynamic>.from(
          json['metadata'] as Map? ?? const {},
        ),
      );
}

class CurveLocalProperties {
  const CurveLocalProperties({
    required this.parameter,
    required this.point,
    required this.tangent,
    required this.normal,
    required this.binormal,
    required this.curvature,
    required this.localRadius,
  });
  final double parameter, curvature, localRadius;
  final List<double> point, tangent, normal, binormal;
}

class CurveClosestPoint {
  const CurveClosestPoint(this.point, this.parameter, this.distance);
  final List<double> point;
  final double parameter, distance;
}

class CurveIntersection {
  const CurveIntersection({
    required this.point,
    required this.parameter,
    this.targetParameter,
    required this.tolerance,
  });
  final List<double> point;
  final double parameter, tolerance;
  final double? targetParameter;
}

class CurveContinuityReport {
  const CurveContinuityReport({
    required this.level,
    required this.positionError,
    required this.tangentError,
    required this.curvatureError,
    required this.tangent,
  });
  final CurveContinuity level;
  final double positionError, tangentError, curvatureError;
  final bool tangent;
}

/// Kernel-backed evaluator used by the entity itself. Implementations delegate
/// to OCCT; no differential or intersection algorithm belongs to Sketch/UI.
abstract interface class CurveGeometryEvaluator {
  Future<CurveLocalProperties> propertiesAt(
    ProfessionalCurve curve,
    double parameter,
  );
  Future<CurveClosestPoint> closestPoint(
    ProfessionalCurve curve,
    List<double> point,
  );
  Future<ProfessionalCurve> projectOntoSurface(
    ProfessionalCurve curve,
    ShapeHandle surface,
  );
  Future<ProfessionalCurve> projectOntoCurve(
    ProfessionalCurve curve,
    ProfessionalCurve target,
  );
  Future<List<CurveIntersection>> intersectCurve(
    ProfessionalCurve curve,
    ProfessionalCurve target,
  );
  Future<List<CurveIntersection>> intersectSurface(
    ProfessionalCurve curve,
    ShapeHandle surface,
  );
  Future<CurveContinuityReport> continuityWithCurve(
    ProfessionalCurve curve,
    ProfessionalCurve target,
  );
  Future<CurveContinuityReport> tangencyWithSurface(
    ProfessionalCurve curve,
    ShapeHandle surface,
  );
}
