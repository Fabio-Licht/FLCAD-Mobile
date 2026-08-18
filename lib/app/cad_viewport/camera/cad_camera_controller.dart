import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../../../core/geometric_kernel/linear_algebra/matrices.dart';

enum CadProjectionMode { perspective, orthographic }

class CadCameraState {
  const CadCameraState({
    required this.eye,
    required this.target,
    required this.rotationCenter,
    required this.focusPoint,
    required this.up,
    required this.projectionMode,
    required this.viewScale,
    required this.nearPlane,
    required this.farPlane,
  });
  final Vector3 eye;
  final Vector3 target;
  final Vector3 rotationCenter;
  final Vector3 focusPoint;
  final Vector3 up;
  final CadProjectionMode projectionMode;
  final double viewScale;
  final double nearPlane;
  final double farPlane;
}

class CadCameraController extends ChangeNotifier {
  CadCameraController({
    // Same initial yaw (.55), pitch (.38), distance (3) and Y-up convention
    // used by the Render Lab reference camera.
    this.eye = const Vector3(
      1.45620343492616,
      1.112761408238948,
      -2.3751281237952884,
    ),
    this.target = Vector3.zero,
    Vector3? rotationCenter,
    Vector3? focusPoint,
    this.up = const Vector3(0, 1, 0),
  }) : rotationCenter = rotationCenter ?? target,
       focusPoint = focusPoint ?? rotationCenter ?? target;

  Vector3 eye;
  Vector3 target;
  Vector3 rotationCenter;
  Vector3 focusPoint;
  Vector3 up;
  CadProjectionMode projectionMode = CadProjectionMode.perspective;
  double viewportWidth = 1;
  double viewportHeight = 1;
  // Shared with the Render Lab reference camera.
  double fieldOfViewRadians = 42 * math.pi / 180;
  double nearPlane = .01;
  double farPlane = 100000;
  double viewScale = 10;
  double get orthographicHeight => viewScale;
  set orthographicHeight(double value) => viewScale = value;
  CadCameraState? _preSketchState;

  bool get isInSketchMode => _preSketchState != null;

  CadCameraState snapshot() => CadCameraState(
    eye: eye,
    target: target,
    rotationCenter: rotationCenter,
    focusPoint: focusPoint,
    up: up,
    projectionMode: projectionMode,
    viewScale: viewScale,
    nearPlane: nearPlane,
    farPlane: farPlane,
  );

  void enterSketch({
    required Vector3 origin,
    required Vector3 normal,
    required Vector3 xDirection,
    double visualSize = 60,
  }) {
    _preSketchState ??= snapshot();
    final n = normal.normalized;
    final x = xDirection.normalized;
    final y = n.cross(x).normalized;
    final currentSide = (eye - origin).dot(n) < 0 ? -1.0 : 1.0;
    final distance = math.max(visualSize * 1.5, .01);
    target = origin;
    rotationCenter = origin;
    focusPoint = origin;
    eye = origin + n * (distance * currentSide);
    // Keep local +Y pointing upward and local +X to the right on either side.
    up = y * -currentSide;
    projectionMode = CadProjectionMode.orthographic;
    viewScale = math.max(visualSize * 1.1, .01);
    nearPlane = math.max(distance / 10000, 1e-6);
    farPlane = math.max(distance * 1000, 10);
    notifyListeners();
  }

  void exitSketch() {
    final state = _preSketchState;
    if (state == null) return;
    eye = state.eye;
    target = state.target;
    rotationCenter = state.rotationCenter;
    focusPoint = state.focusPoint;
    up = state.up;
    projectionMode = state.projectionMode;
    viewScale = state.viewScale;
    nearPlane = state.nearPlane;
    farPlane = state.farPlane;
    _preSketchState = null;
    notifyListeners();
  }

  Matrix4 get viewMatrix {
    final forward = (target - eye).normalized;
    final right = forward.cross(_safeUp()).normalized;
    final cameraUp = right.cross(forward);
    return Matrix4([
      right.x,
      right.y,
      right.z,
      -right.dot(eye),
      cameraUp.x,
      cameraUp.y,
      cameraUp.z,
      -cameraUp.dot(eye),
      -forward.x,
      -forward.y,
      -forward.z,
      forward.dot(eye),
      0,
      0,
      0,
      1,
    ]);
  }

  Matrix4 get projectionMatrix {
    final aspect = viewportWidth / viewportHeight;
    if (projectionMode == CadProjectionMode.orthographic) {
      final halfH = viewScale / 2;
      final halfW = halfH * aspect;
      return Matrix4([
        1 / halfW,
        0,
        0,
        0,
        0,
        1 / halfH,
        0,
        0,
        0,
        0,
        -2 / (farPlane - nearPlane),
        -(farPlane + nearPlane) / (farPlane - nearPlane),
        0,
        0,
        0,
        1,
      ]);
    }
    final f = 1 / math.tan(fieldOfViewRadians / 2);
    return Matrix4([
      f / aspect,
      0,
      0,
      0,
      0,
      f,
      0,
      0,
      0,
      0,
      (farPlane + nearPlane) / (nearPlane - farPlane),
      2 * farPlane * nearPlane / (nearPlane - farPlane),
      0,
      0,
      -1,
      0,
    ]);
  }

  Matrix4 get viewProjectionMatrix => projectionMatrix * viewMatrix;
  Matrix4 get inverseViewMatrix => viewMatrix.inverse();
  Matrix4 get inverseProjectionMatrix => projectionMatrix.inverse();
  Matrix4 get inverseViewProjectionMatrix => viewProjectionMatrix.inverse();

  void resize(double width, double height) {
    if (width <= 0 || height <= 0) return;
    if (viewportWidth == width && viewportHeight == height) return;
    viewportWidth = width;
    viewportHeight = height;
    notifyListeners();
  }

  void orbit(double yaw, double pitch) {
    if (!yaw.isFinite || !pitch.isFinite) return;
    final safeUp = _safeUp();
    var eyeOffset = eye - focusPoint;
    var targetOffset = target - focusPoint;
    eyeOffset = _rotate(eyeOffset, safeUp, -yaw);
    targetOffset = _rotate(targetOffset, safeUp, -yaw);
    final yawEye = focusPoint + eyeOffset;
    final yawTarget = focusPoint + targetOffset;
    final yawForward = (yawTarget - yawEye).normalized;
    var right = yawForward.cross(safeUp);
    if (right.length <= 1e-10) return;
    right = right.normalized;
    final safePitch = pitch.clamp(-math.pi / 2 + .01, math.pi / 2 - .01);
    eyeOffset = _rotate(eyeOffset, right, safePitch);
    targetOffset = _rotate(targetOffset, right, safePitch);
    eye = focusPoint + eyeOffset;
    target = focusPoint + targetOffset;
    final forward = (target - eye).normalized;
    up = right.cross(forward).normalized;
    notifyListeners();
  }

  void pan(double horizontal, double vertical) {
    if (!horizontal.isFinite || !vertical.isFinite) return;
    final viewDirection = target - eye;
    final viewDistance = viewDirection.length;
    if (viewDistance <= 1e-12) return;
    final forward = viewDirection / viewDistance;
    final right = forward.cross(_safeUp()).normalized;
    final cameraUp = right.cross(forward).normalized;
    final delta = right * horizontal + cameraUp * vertical;
    final translatedEye = eye + delta;
    // Reconstruct Target from the unchanged orthonormal camera basis instead
    // of adding to Eye and Target independently. This prevents floating-point
    // cancellation from introducing a residual angular drift during long pan
    // sequences, especially for geometry far from the world origin.
    eye = translatedEye;
    target = translatedEye + forward * viewDistance;
    up = cameraUp;
    rotationCenter = rotationCenter + delta;
    notifyListeners();
  }

  /// Translates the camera parallel to the viewport without changing its
  /// orientation. Positive screen X drags the view to the right; positive
  /// screen Y drags it down, matching a "sheet of paper" pan gesture.
  void panViewportPixels(double deltaX, double deltaY) {
    if (!deltaX.isFinite || !deltaY.isFinite) return;
    final viewDirection = target - eye;
    final worldPerPixel = projectionMode == CadProjectionMode.orthographic
        ? viewScale / math.max(viewportHeight, 1)
        : 2 *
              viewDirection.length *
              math.tan(fieldOfViewRadians / 2) /
              math.max(viewportHeight, 1);
    pan(-deltaX * worldPerPixel, deltaY * worldPerPixel);
  }

  void zoom(double factor, {Vector3? anchor}) {
    if (!factor.isFinite || factor <= 0) return;
    if (projectionMode == CadProjectionMode.orthographic) {
      if (anchor != null) {
        final shift = (anchor - target) * (1 - factor);
        eye = eye + shift;
        target = target + shift;
      }
      viewScale = (viewScale * factor).clamp(.0001, 1e9).toDouble();
    } else {
      final offset = eye - target;
      final direction = offset.length <= 1e-12
          ? const Vector3(1, -1, .7).normalized
          : offset.normalized;
      // Never let the eye cross the target or enter the near clipping plane.
      // Keeping a finite upper bound also prevents a wheel burst from making
      // the model effectively impossible to recover without Fit View.
      final distance = (offset.length * factor)
          .clamp(math.max(nearPlane * 4, .0001), math.min(farPlane * .8, 1e9))
          .toDouble();
      if (anchor == null) {
        eye = target + direction * distance;
      } else {
        final ratio = distance / math.max(offset.length, 1e-12);
        eye = anchor + (eye - anchor) * ratio;
        target = anchor + (target - anchor) * ratio;
      }
      viewScale = (viewScale * factor).clamp(.0001, 1e9).toDouble();
    }
    notifyListeners();
  }

  void setRotationCenter(Vector3 point) {
    if (!point.x.isFinite || !point.y.isFinite || !point.z.isFinite) return;
    rotationCenter = point;
    focusPoint = point;
    notifyListeners();
  }

  void focusOn(Vector3 point) {
    if (!point.x.isFinite || !point.y.isFinite || !point.z.isFinite) return;
    focusPoint = point;
    notifyListeners();
  }

  void fit(Vector3 minimum, Vector3 maximum) {
    final previousDirection = eye - target;
    target = (minimum + maximum) / 2;
    rotationCenter = target;
    focusPoint = target;
    final radius = (maximum - minimum).length / 2;
    final direction = previousDirection.length == 0
        ? const Vector3(1, -1, .7).normalized
        : previousDirection.normalized;
    // Keep Fit, clipping and FOV identical to the Render Lab reference.
    final distance = math.max(radius * 2.7, .01);
    eye = target + direction * distance;
    viewScale = math.max(radius * 2.4, .01);
    nearPlane = math.max(radius * .001, .001);
    farPlane = math.max(radius * 100, 1000);
    notifyListeners();
  }

  void toggleProjection() {
    projectionMode = projectionMode == CadProjectionMode.perspective
        ? CadProjectionMode.orthographic
        : CadProjectionMode.perspective;
    notifyListeners();
  }

  static Vector3 _rotate(Vector3 value, Vector3 axis, double angle) {
    final cosine = math.cos(angle), sine = math.sin(angle);
    return value * cosine +
        axis.cross(value) * sine +
        axis * (axis.dot(value) * (1 - cosine));
  }

  Vector3 _safeUp() {
    final forward = (target - eye).normalized;
    var candidate = up.length <= 1e-10 ? const Vector3(0, 0, 1) : up.normalized;
    if (forward.cross(candidate).length <= 1e-8) {
      candidate = forward.z.abs() < .9
          ? const Vector3(0, 0, 1)
          : const Vector3(0, 1, 0);
    }
    final right = forward.cross(candidate).normalized;
    return right.cross(forward).normalized;
  }
}
