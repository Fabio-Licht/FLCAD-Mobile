import 'navigation_contracts.dart';

enum NavigationPointerPhase { down, move, up, cancel }

class NavigationPointerEvent {
  const NavigationPointerEvent({
    required this.phase,
    required this.x,
    required this.y,
    required this.buttons,
    this.control = false,
    this.shift = false,
    this.alt = false,
  });
  final NavigationPointerPhase phase;
  final double x, y;
  final int buttons;
  final bool control, shift, alt;
}

abstract interface class NavigationStyleHost {
  NavigationState get state;
  void transitionTo(NavigationState state);
  void beginPan(double x, double y);
  void updatePan(double x, double y);
  void orbitBy(double x, double y);
  void zoomByDrag(double y);
  void finishPointerGesture(double x, double y);
  void cancelPointerGesture();
}

abstract interface class NavigationStyle {
  String get name;
  void processPointer(NavigationPointerEvent event, NavigationStyleHost host);
}

/// State and gesture lifecycle adapted conceptually from FreeCAD's CAD and
/// OpenCascade styles. This class owns mappings only, never camera math.
class CadOpenCascadeNavigationStyle implements NavigationStyle {
  const CadOpenCascadeNavigationStyle();
  static const int primaryButton = 1;
  static const int secondaryButton = 2;
  static const int middleButton = 4;

  @override
  String get name => 'CAD / OpenCascade';

  @override
  void processPointer(NavigationPointerEvent event, NavigationStyleHost host) {
    switch (event.phase) {
      case NavigationPointerPhase.down:
        _press(event, host);
      case NavigationPointerPhase.move:
        _move(event, host);
      case NavigationPointerPhase.up:
        _release(event, host);
      case NavigationPointerPhase.cancel:
        host.cancelPointerGesture();
    }
  }

  void _press(NavigationPointerEvent event, NavigationStyleHost host) {
    if (_requestsOrbit(event)) {
      host.transitionTo(NavigationState.orbiting);
    } else if (_requestsPan(event)) {
      host.beginPan(event.x, event.y);
      host.transitionTo(NavigationState.panning);
    } else if (_requestsZoom(event)) {
      host.transitionTo(NavigationState.zooming);
    } else if ((event.buttons & primaryButton) != 0) {
      host.transitionTo(NavigationState.selecting);
    }
  }

  void _move(NavigationPointerEvent event, NavigationStyleHost host) {
    if (_requestsOrbit(event)) {
      host.transitionTo(NavigationState.orbiting);
      host.orbitBy(event.x, event.y);
    } else if (host.state == NavigationState.orbiting && _middleOnly(event)) {
      host.transitionTo(NavigationState.zooming);
      host.zoomByDrag(event.y);
    } else if (_requestsPan(event)) {
      if (host.state != NavigationState.panning) {
        host.beginPan(event.x, event.y);
        host.transitionTo(NavigationState.panning);
      }
      host.updatePan(event.x, event.y);
    } else if (_requestsZoom(event)) {
      host.transitionTo(NavigationState.zooming);
      host.zoomByDrag(event.y);
    }
  }

  void _release(NavigationPointerEvent event, NavigationStyleHost host) {
    if (event.buttons == 0) {
      host.finishPointerGesture(event.x, event.y);
    } else {
      _press(event, host);
    }
  }

  bool _requestsPan(NavigationPointerEvent event) => _middleOnly(event);

  bool _requestsOrbit(NavigationPointerEvent event) =>
      (event.buttons & middleButton) != 0 &&
      ((event.buttons & primaryButton) != 0 || event.shift || event.control);

  bool _requestsZoom(NavigationPointerEvent event) =>
      (event.control && (event.buttons & primaryButton) != 0) ||
      (event.control && event.shift && (event.buttons & middleButton) != 0);

  bool _middleOnly(NavigationPointerEvent event) =>
      (event.buttons & middleButton) != 0 &&
      (event.buttons & (primaryButton | secondaryButton)) == 0 &&
      !event.control &&
      !event.shift;
}
