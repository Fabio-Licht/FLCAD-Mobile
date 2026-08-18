import '../../cad_kernel/models/kernel_models.dart';

enum ProfessionalSurfaceTool {
  loft,
  sweep,
  fill,
  patch,
  blend,
  nurbs,
  extend,
  reduce,
  trim,
  split,
  join,
  offset,
  offsetWalls,
  boundary,
  boundaryExtend,
  boundaryTrim,
  match,
  heal,
  healLocal,
  mergeFaces,
  unsewFace,
  unsewSelected,
  unsewAll,
  replaceFace,
  deleteFace,
  fair,
  morph,
}

enum SurfaceFeatureStatus { editing, preview, committed, cancelled }

enum SurfaceContinuity { g0, g1, g2 }

enum SurfaceOffsetMode { offset, replace, walls, close }

enum SurfaceOffsetDirection { inside, outside, bilateral }

enum SurfaceAnalysisMode {
  zebra,
  curvature,
  gaussian,
  reflection,
  draft,
  g0,
  g1,
  g2,
}

class ProfessionalSurfaceDefinition {
  const ProfessionalSurfaceDefinition({
    required this.id,
    required this.projectId,
    required this.tool,
    required this.name,
    required this.references,
    required this.parameters,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.handle,
    this.groupId,
    this.setIds = const [],
    this.continuity = SurfaceContinuity.g0,
  });

  final String id, projectId, name;
  final ProfessionalSurfaceTool tool;
  final List<String> references;
  final Map<String, dynamic> parameters;
  final SurfaceFeatureStatus status;
  final int revision;
  final DateTime createdAt, updatedAt;
  final ShapeHandle? handle;
  final String? groupId;
  final List<String> setIds;
  final SurfaceContinuity continuity;

  ProfessionalSurfaceDefinition copyWith({
    String? name,
    List<String>? references,
    Map<String, dynamic>? parameters,
    SurfaceFeatureStatus? status,
    int? revision,
    DateTime? updatedAt,
    ShapeHandle? handle,
    String? groupId,
    List<String>? setIds,
    SurfaceContinuity? continuity,
  }) => ProfessionalSurfaceDefinition(
    id: id,
    projectId: projectId,
    tool: tool,
    name: name ?? this.name,
    references: references ?? this.references,
    parameters: parameters ?? this.parameters,
    status: status ?? this.status,
    revision: revision ?? this.revision,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    handle: handle ?? this.handle,
    groupId: groupId ?? this.groupId,
    setIds: setIds ?? this.setIds,
    continuity: continuity ?? this.continuity,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'tool': tool.name,
    'name': name,
    'references': references,
    'parameters': parameters,
    'status': status.name,
    'revision': revision,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'handle': handle?.toJson(),
    'groupId': groupId,
    'setIds': setIds,
    'continuity': continuity.name,
  };

  factory ProfessionalSurfaceDefinition.fromJson(Map<String, dynamic> json) =>
      ProfessionalSurfaceDefinition(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        tool: ProfessionalSurfaceTool.values.byName(json['tool'] as String),
        name: json['name'] as String,
        references: (json['references'] as List).cast<String>(),
        parameters: Map<String, dynamic>.from(json['parameters'] as Map),
        status: SurfaceFeatureStatus.values.byName(json['status'] as String),
        revision: json['revision'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        handle: json['handle'] == null
            ? null
            : ShapeHandle.fromJson(
                Map<String, dynamic>.from(json['handle'] as Map),
              ),
        groupId: json['groupId'] as String?,
        setIds: (json['setIds'] as List? ?? const []).cast<String>(),
        continuity: SurfaceContinuity.values.byName(
          json['continuity'] as String? ?? 'g0',
        ),
      );
}

class SurfacePreviewState {
  const SurfacePreviewState(this.definition, this.transparent);
  final ProfessionalSurfaceDefinition definition;
  final bool transparent;
}

class SurfaceTreeNode {
  const SurfaceTreeNode(
    this.id,
    this.label,
    this.kind, {
    this.children = const [],
  });
  final String id, label, kind;
  final List<SurfaceTreeNode> children;
}
