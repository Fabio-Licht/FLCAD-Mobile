import '../../smart_regions/api/smart_regions_api.dart';
import '../../smart_regions/models/geometry.dart';
import '../../smart_regions/models/smart_region.dart';
import '../../smart_regions/selection/triangle_selection.dart';
import '../types/fel_type.dart';
import '../../reference_engine/api/reference_api.dart';
import '../../reference_engine/models/reference_entity.dart';
import '../../intelligent_sketch/api/sketch_api.dart';
import '../../intelligent_sketch/models/sketch.dart';
import '../../adaptive_surface/api/surface_api.dart';
import '../../adaptive_surface/models/adaptive_surface.dart';
import '../../hybrid_topology/api/topology_api.dart';
import '../../hybrid_topology/hybrid/hybrid_object.dart';
import '../../hybrid_topology/workspace/local_workspace.dart';

class FELExecutionContext {
  FELExecutionContext({
    required this.projectId,
    required this.projectPath,
    required this.regions,
    Map<String, MeshTopology>? meshes,
    Map<String, FELValue>? variables,
    ReferenceApi? references,
    SketchApi? sketches,
    SurfaceApi? surfaces,
    TopologyApi? topology,
  }) : meshes = meshes ?? {},
       variables = variables ?? {},
       references = references ?? ReferenceApi(),
       sketches = sketches ?? SketchApi(),
       surfaces = surfaces ?? SurfaceApi(),
       topology = topology ?? TopologyApi();
  final String projectId, projectPath;
  final SmartRegionsApi regions;
  final Map<String, MeshTopology> meshes;
  final Map<String, FELValue> variables;
  final ReferenceApi references;
  final SketchApi sketches;
  final SurfaceApi surfaces;
  final TopologyApi topology;
  final Map<String, ReferenceEntity> loadedReferences = {};
  final Map<String, IntelligentSketch> loadedSketches = {};
  IntelligentSketch? activeSketch;
  AdaptiveSurface? activeSurface;
  HybridObject? activeHybridObject;
  LocalWorkspace? activeWorkspace;
  SmartRegion? activeRegion;
  TriangleSelection? activeSelection;
  MeshTopology? activeMesh;
  FELValue pipelineValue = FELValue.voidValue;
}
