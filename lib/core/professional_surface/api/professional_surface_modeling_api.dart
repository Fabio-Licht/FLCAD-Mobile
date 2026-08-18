import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../../cad_kernel/io/kernel_io_models.dart';
import '../../cad_kernel/models/kernel_models.dart';
import '../../surface_generation/api/surface_generation_api.dart';
import '../../surface_operations/api/surface_operations_api.dart';
import '../models/professional_surface_models.dart';
import '../repository/professional_surface_repository.dart';

/// Application-level G-103 coordinator. Geometry is always delegated to the
/// configured [GeometryKernelAPI]; this class only owns feature state.
class ProfessionalSurfaceModelingApi {
  ProfessionalSurfaceModelingApi({
    required this.projectId,
    required this.kernel,
    required this.generation,
    required this.operations,
    required this.repository,
  });

  final String projectId;
  final GeometryKernelAPI kernel;
  final SurfaceGenerationApi generation;
  final SurfaceOperationsApi operations;
  final ProfessionalSurfaceRepository repository;
  final Map<String, ProfessionalSurfaceDefinition> _surfaces = {};
  final List<_SurfaceHistoryEntry> _undo = [], _redo = [];
  int _sequence = 0;

  Iterable<ProfessionalSurfaceDefinition> get surfaces => _surfaces.values;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  SurfacePreviewState loft(
    List<String> sections, {
    Map<String, dynamic> parameters = const {},
  }) => begin(
    tool: ProfessionalSurfaceTool.loft,
    references: sections,
    parameters: parameters,
  );

  SurfacePreviewState sweep({
    required String profile,
    required String path,
    Map<String, dynamic> parameters = const {},
  }) => begin(
    tool: ProfessionalSurfaceTool.sweep,
    references: [profile, path],
    parameters: parameters,
  );

  SurfacePreviewState fill(List<String> edges, {double quality = 0.8}) => begin(
    tool: ProfessionalSurfaceTool.fill,
    references: edges,
    parameters: {'quality': quality},
  );

  SurfacePreviewState patch(
    List<String> contours, {
    SurfaceContinuity continuity = SurfaceContinuity.g0,
  }) => begin(
    tool: ProfessionalSurfaceTool.patch,
    references: contours,
    continuity: continuity,
  );

  SurfacePreviewState blend(
    List<String> boundaries, {
    SurfaceContinuity continuity = SurfaceContinuity.g1,
    Map<String, dynamic> parameters = const {},
  }) => begin(
    tool: ProfessionalSurfaceTool.blend,
    references: boundaries,
    continuity: continuity,
    parameters: parameters,
  );

  SurfacePreviewState nurbs({
    String? sourceSurface,
    List<List<double>>? controlPoints,
    int degreeU = 3,
    int degreeV = 3,
  }) => begin(
    tool: ProfessionalSurfaceTool.nurbs,
    references: sourceSurface == null ? const [] : [sourceSurface],
    parameters: {
      'controlPoints': ?controlPoints,
      'degreeU': degreeU,
      'degreeV': degreeV,
      'convert': sourceSurface != null,
    },
  );

  Future<ProfessionalSurfaceDefinition> editNurbs(
    String id, {
    List<List<double>>? controlPoints,
    List<double>? insertKnotsU,
    List<double>? insertKnotsV,
    List<double>? removeKnotsU,
    List<double>? removeKnotsV,
    int? degreeU,
    int? degreeV,
    bool refine = false,
    bool rebuild = false,
  }) {
    final current = _require(id);
    if (current.tool != ProfessionalSurfaceTool.nurbs) {
      throw ArgumentError('$id is not a NURBS feature');
    }
    return edit(
      id,
      parameters: {
        ...current.parameters,
        'controlPoints': ?controlPoints,
        'insertKnotsU': ?insertKnotsU,
        'insertKnotsV': ?insertKnotsV,
        'removeKnotsU': ?removeKnotsU,
        'removeKnotsV': ?removeKnotsV,
        'degreeU': ?degreeU,
        'degreeV': ?degreeV,
        'refine': refine,
        'rebuild': rebuild,
      },
    );
  }

  Future<void> organize(
    String id, {
    String? groupId,
    List<String> setIds = const [],
  }) async {
    final current = _require(id);
    _surfaces[id] = current.copyWith(
      groupId: groupId,
      setIds: List.unmodifiable(setIds),
      updatedAt: DateTime.now(),
    );
    await repository.saveAll(_surfaces.values);
  }

  SurfacePreviewState begin({
    required ProfessionalSurfaceTool tool,
    required List<String> references,
    Map<String, dynamic> parameters = const {},
    String? name,
    SurfaceContinuity continuity = SurfaceContinuity.g0,
  }) {
    _validate(tool, references, parameters, continuity);
    final now = DateTime.now(),
        id = 'surface-feature-${now.microsecondsSinceEpoch}-${_sequence++}';
    final definition = ProfessionalSurfaceDefinition(
      id: id,
      projectId: projectId,
      tool: tool,
      name: name ?? '${_title(tool)} $_sequence',
      references: List.unmodifiable(references),
      parameters: Map.unmodifiable(parameters),
      status: SurfaceFeatureStatus.editing,
      revision: 0,
      createdAt: now,
      updatedAt: now,
      continuity: continuity,
    );
    _surfaces[id] = definition;
    return SurfacePreviewState(definition, true);
  }

  Future<SurfacePreviewState> preview(
    String id, {
    List<String>? references,
    Map<String, dynamic>? parameters,
    SurfaceContinuity? continuity,
  }) async {
    final current = _require(id);
    final candidate = current.copyWith(
      references: references == null ? null : List.unmodifiable(references),
      parameters: parameters == null ? null : Map.unmodifiable(parameters),
      continuity: continuity,
      status: SurfaceFeatureStatus.preview,
      updatedAt: DateTime.now(),
    );
    _validate(
      candidate.tool,
      candidate.references,
      candidate.parameters,
      candidate.continuity,
    );
    final handle = await _executeKernel(candidate, preview: true);
    final next = candidate.copyWith(handle: handle);
    _surfaces[id] = next;
    return SurfacePreviewState(next, true);
  }

  Future<ProfessionalSurfaceDefinition> confirm(String id) async {
    final current = _require(id);
    // Preview handles are transient inspection results. Apply always asks the
    // official kernel for a definitive, separately identified ShapeHandle.
    final handle = await _executeKernel(current, preview: false);
    final committed = current.copyWith(
      handle: handle,
      status: SurfaceFeatureStatus.committed,
      revision: current.revision + 1,
      updatedAt: DateTime.now(),
    );
    _surfaces[id] = committed;
    _undo.add(_SurfaceHistoryEntry(null, committed));
    _redo.clear();
    await repository.saveAll(_surfaces.values);
    return committed;
  }

  Future<ProfessionalSurfaceDefinition> edit(
    String id, {
    List<String>? references,
    Map<String, dynamic>? parameters,
    SurfaceContinuity? continuity,
  }) async {
    final before = _require(id);
    final draft = before.copyWith(
      references: references == null ? null : List.unmodifiable(references),
      parameters: parameters == null ? null : Map.unmodifiable(parameters),
      continuity: continuity,
      status: SurfaceFeatureStatus.editing,
      updatedAt: DateTime.now(),
    );
    _surfaces[id] = draft;
    await preview(id);
    final after = (await confirm(id)).copyWith(revision: before.revision + 1);
    _surfaces[id] = after;
    _undo.removeLast();
    _undo.add(_SurfaceHistoryEntry(before, after));
    await repository.saveAll(_surfaces.values);
    return after;
  }

  void cancel(String id) {
    final current = _require(id);
    if (current.revision == 0) {
      _surfaces.remove(id);
    } else {
      _surfaces[id] = current.copyWith(status: SurfaceFeatureStatus.committed);
    }
  }

  Future<bool> undo() async {
    if (_undo.isEmpty) return false;
    final entry = _undo.removeLast();
    _redo.add(entry);
    if (entry.before == null) {
      _surfaces.remove(entry.after.id);
    } else {
      _restore(entry.before!);
    }
    await repository.saveAll(_surfaces.values);
    return true;
  }

  Future<bool> redo() async {
    if (_redo.isEmpty) return false;
    final entry = _redo.removeLast();
    _undo.add(entry);
    _restore(entry.after);
    await repository.saveAll(_surfaces.values);
    return true;
  }

  Future<List<ProfessionalSurfaceDefinition>> load() async {
    final loaded = await repository.loadAll();
    _surfaces.clear();
    for (final surface in loaded) {
      _restore(surface);
    }
    return loaded;
  }

  List<SurfaceTreeNode> buildTree() {
    const ordered = [
      ProfessionalSurfaceTool.patch,
      ProfessionalSurfaceTool.loft,
      ProfessionalSurfaceTool.sweep,
      ProfessionalSurfaceTool.blend,
      ProfessionalSurfaceTool.fill,
    ];
    final featureNodes = <SurfaceTreeNode>[
      for (final tool in ordered)
        SurfaceTreeNode(
          'surface-tool:${tool.name}',
          _title(tool),
          tool.name,
          children: _surfaces.values
              .where((value) => value.tool == tool)
              .map((value) => SurfaceTreeNode(value.id, value.name, 'surface'))
              .toList(),
        ),
    ];
    return [
      SurfaceTreeNode('surface-groups', 'Surface Groups', 'group'),
      SurfaceTreeNode('surface-sets', 'Surface Sets', 'set'),
      ...featureNodes,
    ];
  }

  Future<Map<String, dynamic>> analyze(
    String id,
    Set<SurfaceAnalysisMode> modes, {
    List<double> draftDirection = const [0, 0, 1],
  }) async {
    final surface = _require(id);
    final handle =
        surface.handle ?? (throw StateError('Surface $id has no kernel shape'));
    if (kernel is! SurfaceQualityKernelAPI) {
      throw UnsupportedError(
        'The active kernel does not expose real-time surface analysis',
      );
    }
    final api = kernel as SurfaceQualityKernelAPI;
    final quality = await api.inspectSurfaceQuality(
      handle,
      draftDirection: draftDirection,
    );
    return {
      'surfaceId': id,
      'modes': modes.map((e) => e.name).toList(),
      ...quality,
    };
  }

  Future<ShapeHandle> _executeKernel(
    ProfessionalSurfaceDefinition value, {
    required bool preview,
  }) async {
    final transaction = KernelTransaction(
      'g103-${DateTime.now().microsecondsSinceEpoch}',
      projectId,
      kernel.descriptor.id,
      DateTime.now(),
      TransactionStatus.active,
      const [],
    );
    await kernel.begin(transaction);
    try {
      final persistedHandles =
          (value.parameters['shapeHandles'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => ShapeHandle.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false);
      final editing = !{
        ProfessionalSurfaceTool.loft,
        ProfessionalSurfaceTool.sweep,
        ProfessionalSurfaceTool.fill,
        ProfessionalSurfaceTool.patch,
        ProfessionalSurfaceTool.nurbs,
      }.contains(value.tool);
      final kernelReferences = editing
          ? persistedHandles
                .skip(1)
                .where((handle) {
                  if (value.tool != ProfessionalSurfaceTool.offsetWalls) {
                    return true;
                  }
                  final explicitOpen =
                      (value.parameters['openBoundaryIds'] as List? ?? const [])
                          .whereType<String>()
                          .toSet();
                  return !value.parameters.containsKey('openBoundaryIds') ||
                      explicitOpen.contains(handle.persistentId);
                })
                .toList(growable: false)
          : persistedHandles;
      final handle = await kernel.create(
        _operation(value.tool),
        {
          ...value.parameters,
          if (editing && persistedHandles.isNotEmpty)
            'source': persistedHandles.first,
          'references': persistedHandles.isEmpty
              ? value.references
              : editing
              ? kernelReferences
              : persistedHandles,
          'continuity': value.continuity.name.toUpperCase(),
          'preview': preview,
        },
        persistentId:
            '${value.id}-r${value.revision + 1}${preview ? '-preview' : ''}',
        expectedType: CADShapeType.face,
        transaction: transaction,
      );
      final diagnostics = await kernel.validate(handle, const {
        'geometry',
        'bounds',
        'continuity',
        'tolerance',
      });
      if (diagnostics.any((value) => value.startsWith('error:'))) {
        throw StateError(diagnostics.join('; '));
      }
      await kernel.commit(transaction);
      return handle;
    } catch (_) {
      await kernel.rollback(transaction);
      rethrow;
    }
  }

  void _restore(ProfessionalSurfaceDefinition value) {
    _surfaces[value.id] = value;
  }

  ProfessionalSurfaceDefinition _require(String id) =>
      _surfaces[id] ?? (throw StateError('Unknown surface feature: $id'));

  void _validate(
    ProfessionalSurfaceTool tool,
    List<String> references,
    Map<String, dynamic> parameters,
    SurfaceContinuity continuity,
  ) {
    if (references.any((value) => value.trim().isEmpty)) {
      throw ArgumentError('Surface references cannot be empty');
    }
    switch (tool) {
      case ProfessionalSurfaceTool.loft:
        if (references.length < 2) {
          throw ArgumentError('Loft requires two or more sections');
        }
      case ProfessionalSurfaceTool.sweep:
        if (references.length != 2) {
          throw ArgumentError('Sweep requires a profile and a path');
        }
      case ProfessionalSurfaceTool.fill:
      case ProfessionalSurfaceTool.patch:
        if (references.isEmpty) {
          throw ArgumentError('${_title(tool)} requires boundary references');
        }
      case ProfessionalSurfaceTool.blend:
        if (references.length < 2) {
          throw ArgumentError('Blend requires two surface boundaries');
        }
      case ProfessionalSurfaceTool.nurbs:
        if (references.isEmpty && !parameters.containsKey('controlPoints')) {
          throw ArgumentError('NURBS requires a source or control points');
        }
      case ProfessionalSurfaceTool.offsetWalls:
        if (references.isEmpty) {
          throw ArgumentError('Offset requires a source Surface or Shape');
        }
        final mode = parameters['offsetMode'] as String? ?? 'walls';
        if ((mode == 'walls' || mode == 'close') && references.length < 2) {
          throw ArgumentError(
            '$mode requires explicit Boundary selections for Wall/Open choices',
          );
        }
        if (mode == 'walls' || mode == 'close') {
          final declared = <String>{
            ...(parameters['wallBoundaryIds'] as List? ?? const [])
                .whereType<String>(),
            ...(parameters['openBoundaryIds'] as List? ?? const [])
                .whereType<String>(),
          };
          final expected = references.skip(1).toSet();
          if (!declared.containsAll(expected)) {
            throw ArgumentError(
              'Every Boundary must be explicitly classified as Wall or Open',
            );
          }
        }
      default:
        if (references.isEmpty) {
          throw ArgumentError('${_title(tool)} requires a target surface');
        }
    }
    if (continuity == SurfaceContinuity.g2 &&
        parameters['g2Supported'] == false) {
      throw UnsupportedError(
        'G2 is not supported by the selected kernel operation',
      );
    }
  }

  static String _operation(ProfessionalSurfaceTool tool) => switch (tool) {
    ProfessionalSurfaceTool.loft => 'CREATE SURFACE LOFT',
    ProfessionalSurfaceTool.sweep => 'CREATE SURFACE SWEEP',
    ProfessionalSurfaceTool.fill => 'CREATE SURFACE FILL',
    ProfessionalSurfaceTool.patch => 'CREATE SURFACE PATCH',
    ProfessionalSurfaceTool.blend => 'CREATE SURFACE BLEND',
    ProfessionalSurfaceTool.nurbs => 'CREATE OR EDIT NURBS SURFACE',
    ProfessionalSurfaceTool.mergeFaces => 'EDIT SURFACE MERGE FACES',
    ProfessionalSurfaceTool.healLocal => 'EDIT SURFACE HEAL LOCAL',
    ProfessionalSurfaceTool.unsewFace => 'EDIT SURFACE UNSEW FACE',
    ProfessionalSurfaceTool.unsewSelected => 'EDIT SURFACE UNSEW SELECTED',
    ProfessionalSurfaceTool.unsewAll => 'EDIT SURFACE UNSEW ALL',
    ProfessionalSurfaceTool.replaceFace => 'EDIT SURFACE REPLACE FACE',
    ProfessionalSurfaceTool.deleteFace => 'EDIT SURFACE DELETE FACE',
    ProfessionalSurfaceTool.offsetWalls => 'EDIT SURFACE OFFSET WALLS',
    ProfessionalSurfaceTool.boundaryExtend => 'EDIT SURFACE BOUNDARY EXTEND',
    ProfessionalSurfaceTool.boundaryTrim => 'EDIT SURFACE BOUNDARY TRIM',
    _ => 'EDIT SURFACE ${tool.name.toUpperCase()}',
  };

  static String _title(ProfessionalSurfaceTool tool) =>
      '${tool.name[0].toUpperCase()}${tool.name.substring(1)}';
}

class _SurfaceHistoryEntry {
  const _SurfaceHistoryEntry(this.before, this.after);
  final ProfessionalSurfaceDefinition? before;
  final ProfessionalSurfaceDefinition after;
}
