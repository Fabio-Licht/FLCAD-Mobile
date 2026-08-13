import '../models/studio_models.dart';

class LayoutManager {
  StudioLayout _layout;
  LayoutManager({StudioLayout? initial})
    : _layout = initial ?? defaults(StudioProfile.reverseEngineering);
  StudioLayout get layout => _layout;
  void apply(StudioLayout value) => _layout = value;
  static StudioLayout defaults(StudioProfile profile) {
    final panels = [
      const DockPanelState(StudioPanelType.explorer, DockPosition.left),
      const DockPanelState(
        StudioPanelType.engineeringTree,
        DockPosition.left,
        order: 1,
      ),
      const DockPanelState(StudioPanelType.properties, DockPosition.right),
      const DockPanelState(
        StudioPanelType.workflow,
        DockPosition.right,
        order: 1,
      ),
      const DockPanelState(StudioPanelType.timeline, DockPosition.bottom),
    ];
    return StudioLayout(
      id: 'layout:${profile.name}',
      viewportLayout: ViewportLayout.single,
      viewports: const [
        StudioViewport(id: 'viewport:1', camera: StudioCameraState()),
      ],
      panels: panels,
      theme: StudioTheme.professionalBlue,
      profile: profile,
    );
  }
}

class DockManager {
  DockManager(this.layouts);
  final LayoutManager layouts;
  void move(
    StudioPanelType type,
    DockPosition position, {
    bool detached = false,
  }) => layouts.apply(
    _copy(
      panels: layouts.layout.panels
          .map(
            (p) => p.type == type
                ? p.copyWith(position: position, detached: detached)
                : p,
          )
          .toList(),
    ),
  );
  void toggle(StudioPanelType type) {
    if (!layouts.layout.panels.any((e) => e.type == type)) {
      throw StateError('Panel ${type.name} is not part of this layout');
    }
    layouts.apply(
      _copy(
        panels: layouts.layout.panels
            .map((e) => e.type == type ? e.copyWith(visible: !e.visible) : e)
            .toList(),
      ),
    );
  }

  StudioLayout _copy({List<DockPanelState>? panels}) {
    final l = layouts.layout;
    return StudioLayout(
      id: l.id,
      viewportLayout: l.viewportLayout,
      viewports: l.viewports,
      panels: panels ?? l.panels,
      theme: l.theme,
      profile: l.profile,
    );
  }
}

class ViewManager {
  ViewManager(this.layouts);
  final LayoutManager layouts;
  void configure(ViewportLayout type, {int? customCount}) {
    final count = switch (type) {
      ViewportLayout.single => 1,
      ViewportLayout.horizontalSplit || ViewportLayout.verticalSplit => 2,
      ViewportLayout.quad => 4,
      ViewportLayout.custom => customCount ?? 1,
    };
    if (count < 1 || count > 8) {
      throw ArgumentError('Viewport count must be 1..8');
    }
    final l = layouts.layout;
    layouts.apply(
      StudioLayout(
        id: l.id,
        viewportLayout: type,
        viewports: List.generate(
          count,
          (i) => StudioViewport(
            id: 'viewport:${i + 1}',
            camera: const StudioCameraState(),
          ),
        ),
        panels: l.panels,
        theme: l.theme,
        profile: l.profile,
      ),
    );
  }
}

class WorkspaceManager {
  final Map<String, LayoutManager> _projects = {};
  String? activeProjectId;
  LayoutManager open(String projectId) {
    activeProjectId = projectId;
    return _projects.putIfAbsent(projectId, LayoutManager.new);
  }

  void close(String id) {
    _projects.remove(id);
    if (activeProjectId == id) activeProjectId = null;
  }

  List<String> get openProjects => List.unmodifiable(_projects.keys);
}
