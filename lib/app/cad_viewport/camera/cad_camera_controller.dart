import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../../../core/geometric_kernel/linear_algebra/matrices.dart';

enum CadProjectionMode { perspective, orthographic }

class CadCameraState {
  const CadCameraState({
    required this.eye,
    required this.target,
    required this.up,
    required this.projectionMode,
    required this.orthographicHeight,
    required this.nearPlane,
    required this.farPlane,
  });
  final Vector3 eye;
  final Vector3 target;
  final Vector3 up;
  final CadProjectionMode projectionMode;
  final double orthographicHeight;
  final double nearPlane;
  final double farPlane;
}

class CadCameraController extends ChangeNotifier {
  CadCameraController({
    this.eye = const Vector3(6, -6, 4),
    this.target = Vector3.zero,
    this.up = const Vector3(0, 0, 1),
  });

  Vector3 eye;
  Vector3 target;
  Vector3 up;
  CadProjectionMode projectionMode = CadProjectionMode.perspective;
  double viewportWidth = 1;
  double viewportHeight = 1;
  double fieldOfViewRadians = math.pi / 4;
  double nearPlane = .01;
  double farPlane = 100000;
  double orthographicHeight = 10;
  CadCameraState? _preSketchState;

  bool get isInSketchMode => _preSketchState != null;

  CadCameraState snapshot() => CadCameraState(
    eye: eye,
    target: target,
    up: up,
    projectionMode: projectionMode,
    orthographicHeight: orthographicHeight,
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
    eye = origin + n * (distance * currentSide);
    // Keep local +Y pointing upward and local +X to the right on either side.
    up = y * -currentSide;
    projectionMode = CadProjectionMode.orthographic;
    orthographicHeight = math.max(visualSize * 1.1, .01);
    nearPlane = math.max(distance / 10000, 1e-6);
    farPlane = math.max(distance * 1000, 10);
    notifyListeners();
  }

  void exitSketch() {
    final state = _preSketchState;
    if (state == null) return;
    eye = state.eye;
    target = state.target;
    up = state.up;
    projectionMode = state.projectionMode;
    orthographicHeight = state.orthographicHeight;
    nearPlane = state.nearPlane;
    farPlane = state.farPlane;
    _preSketchState = null;
    notifyListeners();
  }

  Matrix4 get viewMatrix {
    final forward = (target - eye).normalized;
    final right = forward.cross(up).normalized;
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
      final halfH = orthographicHeight / 2;
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
    var offset = eye - target;
    offset = _rotate(offset, up.normalized, -yaw);
    final forward = (-offset).normalized;
    final right = forward.cross(up).normalized;
    offset = _rotate(offset, right, pitch);
    eye = target + offset;
    up = right.cross((target - eye).normalized).normalized;
    notifyListeners();
  }

  void pan(double horizontal, double vertical) {
    final forward = (target - eye).normalized;
    final right = forward.cross(up).normalized;
    final delta = right * horizontal + up.normalized * vertical;
    eye = eye + delta;
    target = target + delta;
    notifyListeners();
  }

  void zoom(double factor) {
    if (!factor.isFinite || factor <= 0) return;
    if (projectionMode == CadProjectionMode.orthographic) {
      orthographicHeight = (orthographicHeight * factor).clamp(.0001, 1e9);
    } else {
      final offset = eye - target;
      eye = target + offset * factor.clamp(.02, 50);
    }
    notifyListeners();
  }

  void fit(Vector3 minimum, Vector3 maximum) {
    final previousDirection = eye - target;
    target = (minimum + maximum) / 2;
    final radius = (maximum - minimum).length / 2;
    final direction = previousDirection.length == 0
        ? const Vector3(1, -1, .7).normalized
        : previousDirection.normalized;
    // Keep the complete bounding sphere inside the perspective frustum even
    // after orbiting to an oblique view.  At a 45 degree vertical FOV the
    // theoretical minimum is ~2.62 radii; use a practical CAD fit margin so
    // corners are not clipped by perspective or viewport aspect rounding.
    final distance = math.max(radius * 3.5, .01);
    eye = target + direction * distance;
    orthographicHeight = math.max(radius * 2.4, .01);
    nearPlane = math.max(distance / 10000, 1e-6);
    farPlane = math.max(distance * 1000, 10);
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
}
