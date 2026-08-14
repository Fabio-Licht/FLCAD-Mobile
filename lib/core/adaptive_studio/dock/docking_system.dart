import '../models/adaptive_studio_models.dart';

class DockingSystem {
  void dock(AdaptivePanel panel) => panel.dockState = DockState.docked;
  void undock(AdaptivePanel panel) => panel.dockState = DockState.undocked;
  void autoHide(AdaptivePanel panel) => panel.dockState = DockState.autoHidden;
  void pin(AdaptivePanel panel) => panel.dockState = DockState.pinned;
  void float(AdaptivePanel panel, {int monitor = 0}) {
    panel
      ..dockState = DockState.floating
      ..monitor = monitor;
  }

  void snap(AdaptivePanel panel) => panel.dockState = DockState.snapped;
}
