enum StudioProfile {
  reverseEngineering,
  inspection,
  cad,
  scan,
  minimal,
  expert,
}

enum StudioTheme { dark, light, professionalBlue, highContrast }

enum ViewportLayout { single, horizontalSplit, verticalSplit, quad, custom }

enum DockPosition { left, right, top, bottom, center, floating, hidden }

enum StudioPanelType {
  explorer,
  engineeringTree,
  properties,
  inspector,
  timeline,
  workflow,
  recognition,
  reconstruction,
  decision,
  console,
  output,
  surfaceGeneration,
  kernelStatus,
}

enum StudioEntityType {
  project,
  mesh,
  region,
  reference,
  sketch,
  surface,
  feature,
  recognition,
  workflow,
  decision,
  analytics,
  vertex,
  edge,
  wire,
  face,
  shell,
  solid,
  body,
  cadFeature,
  surfacePlan,
  surfaceCandidate,
  generatedSurfaces,
  generatedSurface,
  hybridSurfaceNetwork,
  hybridSurface,
  kernelStatus,
}

enum SelectionMode { single, multiple, box, lasso }

enum OverlayType {
  regions,
  confidence,
  heatmap,
  axes,
  planes,
  vectors,
  advisor,
}

enum RenderLayerType {
  mesh,
  references,
  sketch,
  regions,
  surfacePlans,
  featurePlans,
  decisionOverlay,
  workflowOverlay,
}

class StudioCameraState {
  const StudioCameraState({
    this.position = const [4, 4, 4],
    this.target = const [0, 0, 0],
    this.up = const [0, 0, 1],
    this.orthographic = false,
    this.zoom = 1,
  });
  final List<double> position, target, up;
  final bool orthographic;
  final double zoom;
  Map<String, dynamic> toJson() => {
    'position': position,
    'target': target,
    'up': up,
    'orthographic': orthographic,
    'zoom': zoom,
  };
  factory StudioCameraState.fromJson(Map<String, dynamic> j) =>
      StudioCameraState(
        position: (j['position'] as List)
            .cast<num>()
            .map((e) => e.toDouble())
            .toList(),
        target: (j['target'] as List)
            .cast<num>()
            .map((e) => e.toDouble())
            .toList(),
        up: (j['up'] as List).cast<num>().map((e) => e.toDouble()).toList(),
        orthographic: j['orthographic'] as bool,
        zoom: (j['zoom'] as num).toDouble(),
      );
}

class StudioViewport {
  const StudioViewport({
    required this.id,
    required this.camera,
    this.grid = true,
    this.orientation = 'isometric',
    this.clippingNear = .01,
    this.clippingFar = 100000,
    this.renderBackend = 'contract',
  });
  final String id, orientation, renderBackend;
  final StudioCameraState camera;
  final bool grid;
  final double clippingNear, clippingFar;
}

class DockPanelState {
  const DockPanelState(
    this.type,
    this.position, {
    this.visible = true,
    this.detached = false,
    this.size = .25,
    this.order = 0,
  });
  final StudioPanelType type;
  final DockPosition position;
  final bool visible, detached;
  final double size;
  final int order;
  DockPanelState copyWith({
    DockPosition? position,
    bool? visible,
    bool? detached,
    double? size,
    int? order,
  }) => DockPanelState(
    type,
    position ?? this.position,
    visible: visible ?? this.visible,
    detached: detached ?? this.detached,
    size: size ?? this.size,
    order: order ?? this.order,
  );
}

class EngineeringTreeNode {
  const EngineeringTreeNode({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    this.parentId,
    this.visible = true,
    this.locked = false,
    this.selected = false,
    this.status = 'ready',
    this.confidence = 1,
    this.context = const {},
  });
  final String id, projectId, name, status;
  final StudioEntityType type;
  final String? parentId;
  final bool visible, locked, selected;
  final double confidence;
  final Map<String, dynamic> context;
  EngineeringTreeNode copyWith({bool? visible, bool? locked, bool? selected}) =>
      EngineeringTreeNode(
        id: id,
        projectId: projectId,
        name: name,
        type: type,
        parentId: parentId,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        selected: selected ?? this.selected,
        status: status,
        confidence: confidence,
        context: context,
      );
}

class StudioLayout {
  const StudioLayout({
    required this.id,
    required this.viewportLayout,
    required this.viewports,
    required this.panels,
    required this.theme,
    required this.profile,
  });
  final String id;
  final ViewportLayout viewportLayout;
  final List<StudioViewport> viewports;
  final List<DockPanelState> panels;
  final StudioTheme theme;
  final StudioProfile profile;
}

class StudioSelection {
  const StudioSelection(this.ids, this.mode, this.filter);
  final Set<String> ids;
  final SelectionMode mode;
  final Set<StudioEntityType> filter;
}

class RenderLayer {
  const RenderLayer(this.type, {this.enabled = true, this.opacity = 1});
  final RenderLayerType type;
  final bool enabled;
  final double opacity;
}

class OverlayState {
  const OverlayState(this.type, {this.enabled = false, this.opacity = .75});
  final OverlayType type;
  final bool enabled;
  final double opacity;
}

class StudioNotification {
  const StudioNotification(
    this.id,
    this.message,
    this.severity,
    this.timestamp, {
    this.action,
  });
  final String id, message, severity;
  final DateTime timestamp;
  final String? action;
}

class PerformanceHUDSnapshot {
  const PerformanceHUDSnapshot({
    required this.fps,
    required this.memoryBytes,
    required this.triangles,
    required this.drawCalls,
    required this.recognitionTime,
    required this.activeRuntimeTasks,
  });
  final double fps;
  final int memoryBytes, triangles, drawCalls, activeRuntimeTasks;
  final Duration recognitionTime;
}
