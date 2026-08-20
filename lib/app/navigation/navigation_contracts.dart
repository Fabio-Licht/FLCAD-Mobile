import '../../core/geometric_kernel/geometry/vectors.dart';

enum NavigationState {
  idle,
  hover,
  selecting,
  orbiting,
  panning,
  zooming,
  boxZoom,
  seek,
  dragging,
  sketchNavigation,
  sectionNavigation,
}

enum NavigationProfile {
  objectManipulationTest,
  cadOpenCascade,
  geomagicCatia,
  catia,
  geomagic,
  flcadClassic,
  flcadReverseEngineering,
}

/// Internal calibration of an approved operational profile. These values are
/// implementation details and are not part of the public camera contract.
class NavigationProfileCalibration {
  const NavigationProfileCalibration({
    required this.orbitPixelsPerRadian,
    required this.panGain,
    required this.wheelExponent,
    required this.dragZoomExponent,
    required this.fitBoundsExpansion,
    required this.zoomSessionTimeout,
  });

  final double orbitPixelsPerRadian;
  final double panGain;
  final double wheelExponent;
  final double dragZoomExponent;
  final double fitBoundsExpansion;
  final Duration zoomSessionTimeout;

  static const geomagicCatia = NavigationProfileCalibration(
    orbitPixelsPerRadian: 220,
    panGain: 1,
    wheelExponent: .001,
    dragZoomExponent: .0065,
    fitBoundsExpansion: 1.3,
    zoomSessionTimeout: Duration(milliseconds: 220),
  );

  static const classic = NavigationProfileCalibration(
    orbitPixelsPerRadian: 180,
    panGain: 1,
    wheelExponent: .001,
    dragZoomExponent: .008,
    fitBoundsExpansion: 1,
    zoomSessionTimeout: Duration(milliseconds: 220),
  );

  static const objectManipulation = NavigationProfileCalibration(
    // Professional Orbit: a longer hand movement is required for the same
    // angular displacement, preserving direct linear control without easing.
    orbitPixelsPerRadian: 320,
    panGain: 1,
    wheelExponent: .001,
    dragZoomExponent: .008,
    fitBoundsExpansion: 1,
    zoomSessionTimeout: Duration(milliseconds: 220),
  );

  static NavigationProfileCalibration forProfile(NavigationProfile profile) =>
      switch (profile) {
        NavigationProfile.objectManipulationTest => objectManipulation,
        NavigationProfile.cadOpenCascade => classic,
        NavigationProfile.geomagicCatia ||
        NavigationProfile.catia ||
        NavigationProfile.geomagic => geomagicCatia,
        NavigationProfile.flcadClassic => classic,
        NavigationProfile.flcadReverseEngineering => geomagicCatia,
      };
}

enum NavigationContext {
  viewport,
  sketch,
  section,
  inspection,
  mesh,
  surface,
  assembly,
}

enum NavigationCommandPhase { begin, update, end }

sealed class NavigationCommand {
  const NavigationCommand();
}

final class OrbitCommand extends NavigationCommand {
  const OrbitCommand(this.yaw, this.pitch);
  final double yaw;
  final double pitch;
}

final class PanCommand extends NavigationCommand {
  const PanCommand({
    required this.phase,
    this.previousX = 0,
    this.previousY = 0,
    this.currentX = 0,
    this.currentY = 0,
  });
  final NavigationCommandPhase phase;
  final double previousX;
  final double previousY;
  final double currentX;
  final double currentY;
}

final class ManipulateOperationalSceneCommand extends NavigationCommand {
  const ManipulateOperationalSceneCommand({
    required this.phase,
    this.previousX = 0,
    this.previousY = 0,
    this.currentX = 0,
    this.currentY = 0,
  });
  final NavigationCommandPhase phase;
  final double previousX, previousY, currentX, currentY;
}

final class ZoomCommand extends NavigationCommand {
  const ZoomCommand(this.factor, {this.anchor});
  final double factor;
  final Vector3? anchor;
}

final class FitCommand extends NavigationCommand {
  const FitCommand(this.minimum, this.maximum);
  final Vector3 minimum;
  final Vector3 maximum;
}

final class SetRotationCenterCommand extends NavigationCommand {
  const SetRotationCenterCommand(this.point);
  final Vector3 point;
}

final class FocusCommand extends NavigationCommand {
  const FocusCommand(this.point);
  final Vector3 point;
}

abstract interface class NavigationCameraContract {
  void execute(NavigationCommand command);
  Object get snapshot;
}

typedef NavigationPointResolver = Vector3? Function(double x, double y);

class NavigationDebugSnapshot {
  const NavigationDebugSnapshot({
    required this.state,
    required this.profile,
    required this.context,
    required this.command,
    required this.timestamp,
    required this.destination,
    this.fps,
    this.pickingState = 'idle',
  });

  final NavigationState state;
  final NavigationProfile profile;
  final NavigationContext context;
  final String command;
  final DateTime timestamp;
  final String destination;
  final double? fps;
  final String pickingState;
}
