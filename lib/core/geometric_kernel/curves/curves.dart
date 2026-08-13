import 'dart:math' as math;
import '../geometry/vectors.dart';

abstract interface class ParametricCurve3 {
  ({double min, double max}) get domain;
  Vector3 evaluate(double parameter);
  Vector3 derivative(double parameter);
}

class LineCurve3 implements ParametricCurve3 {
  const LineCurve3(this.origin, this.direction);
  final Vector3 origin, direction;
  @override
  ({double min, double max}) get domain =>
      (min: double.negativeInfinity, max: double.infinity);
  @override
  Vector3 evaluate(double t) => origin + direction * t;
  @override
  Vector3 derivative(double t) => direction;
}

class CircleCurve3 implements ParametricCurve3 {
  const CircleCurve3(this.center, this.xAxis, this.yAxis, this.radius);
  final Vector3 center, xAxis, yAxis;
  final double radius;
  @override
  ({double min, double max}) get domain => (min: 0, max: 2 * math.pi);
  @override
  Vector3 evaluate(double t) =>
      center +
      xAxis.normalized * (radius * math.cos(t)) +
      yAxis.normalized * (radius * math.sin(t));
  @override
  Vector3 derivative(double t) =>
      xAxis.normalized * (-radius * math.sin(t)) +
      yAxis.normalized * (radius * math.cos(t));
}

class ArcCurve3 extends CircleCurve3 {
  const ArcCurve3(
    super.center,
    super.xAxis,
    super.yAxis,
    super.radius,
    this.start,
    this.end,
  );
  final double start, end;
  @override
  ({double min, double max}) get domain => (min: start, max: end);
}

class EllipseCurve3 implements ParametricCurve3 {
  const EllipseCurve3(this.center, this.majorAxis, this.minorAxis);
  final Vector3 center, majorAxis, minorAxis;
  @override
  ({double min, double max}) get domain => (min: 0, max: 2 * math.pi);
  @override
  Vector3 evaluate(double t) =>
      center + majorAxis * math.cos(t) + minorAxis * math.sin(t);
  @override
  Vector3 derivative(double t) =>
      majorAxis * (-math.sin(t)) + minorAxis * math.cos(t);
}

class BezierCurve3 implements ParametricCurve3 {
  BezierCurve3(List<Vector3> points)
    : controlPoints = List.unmodifiable(points) {
    if (points.length < 2) throw ArgumentError('Two control points required');
  }
  final List<Vector3> controlPoints;
  @override
  ({double min, double max}) get domain => (min: 0, max: 1);
  @override
  Vector3 evaluate(double t) {
    var work = List<Vector3>.from(controlPoints);
    for (var level = work.length - 1; level > 0; level--) {
      for (var i = 0; i < level; i++) {
        work[i] = work[i] * (1 - t) + work[i + 1] * t;
      }
    }
    return work.first;
  }

  @override
  Vector3 derivative(double t) => BezierCurve3(
    List.generate(
      controlPoints.length - 1,
      (i) =>
          (controlPoints[i + 1] - controlPoints[i]) *
          (controlPoints.length - 1),
    ),
  ).evaluate(t);
}

class PolylineCurve3 implements ParametricCurve3 {
  PolylineCurve3(List<Vector3> points) : points = List.unmodifiable(points) {
    if (points.length < 2) throw ArgumentError('Two points required');
  }
  final List<Vector3> points;
  @override
  ({double min, double max}) get domain =>
      (min: 0, max: (points.length - 1).toDouble());
  @override
  Vector3 evaluate(double t) {
    final v = t.clamp(0, points.length - 1.0).toDouble();
    final i = math.min(v.floor(), points.length - 2);
    return points[i] * (1 - (v - i)) + points[i + 1] * (v - i);
  }

  @override
  Vector3 derivative(double t) {
    final i = math.min(
      t.clamp(0, points.length - 2.0).floor(),
      points.length - 2,
    );
    return points[i + 1] - points[i];
  }
}

class HelixCurve3 implements ParametricCurve3 {
  const HelixCurve3(
    this.origin,
    this.axis,
    this.xAxis,
    this.radius,
    this.pitch,
    this.turns,
  );
  final Vector3 origin, axis, xAxis;
  final double radius, pitch, turns;
  Vector3 get _y => axis.normalized.cross(xAxis.normalized);
  @override
  ({double min, double max}) get domain => (min: 0, max: turns * 2 * math.pi);
  @override
  Vector3 evaluate(double t) =>
      origin +
      xAxis.normalized * (radius * math.cos(t)) +
      _y * (radius * math.sin(t)) +
      axis.normalized * (pitch * t / (2 * math.pi));
  @override
  Vector3 derivative(double t) =>
      xAxis.normalized * (-radius * math.sin(t)) +
      _y * (radius * math.cos(t)) +
      axis.normalized * (pitch / (2 * math.pi));
}

class BSplineCurve3 implements ParametricCurve3 {
  BSplineCurve3(this.degree, List<Vector3> controlPoints, List<double> knots)
    : controlPoints = List.unmodifiable(controlPoints),
      knots = List.unmodifiable(knots) {
    if (knots.length != controlPoints.length + degree + 1) {
      throw ArgumentError('Invalid knot vector');
    }
  }
  final int degree;
  final List<Vector3> controlPoints;
  final List<double> knots;
  @override
  ({double min, double max}) get domain =>
      (min: knots[degree], max: knots[controlPoints.length]);
  @override
  Vector3 evaluate(double t) {
    final u = t.clamp(domain.min, domain.max).toDouble();
    var k = degree;
    while (k + 1 < controlPoints.length && u >= knots[k + 1]) {
      k++;
    }
    final d = List.generate(degree + 1, (j) => controlPoints[k - degree + j]);
    for (var r = 1; r <= degree; r++) {
      for (var j = degree; j >= r; j--) {
        final i = k - degree + j, den = knots[i + degree - r + 1] - knots[i];
        final a = den == 0 ? 0.0 : (u - knots[i]) / den;
        d[j] = d[j - 1] * (1 - a) + d[j] * a;
      }
    }
    return d[degree];
  }

  @override
  Vector3 derivative(double t) {
    final h = math.max(1e-7, (domain.max - domain.min) * 1e-6);
    return (evaluate(t + h) - evaluate(t - h)) / (2 * h);
  }
}

class NurbsCurve3 implements ParametricCurve3 {
  NurbsCurve3(
    this.degree,
    List<Vector3> points,
    List<double> weights,
    List<double> knots,
  ) : points = List.unmodifiable(points),
      weights = List.unmodifiable(weights),
      knots = List.unmodifiable(knots) {
    if (points.length != weights.length ||
        knots.length != points.length + degree + 1) {
      throw ArgumentError('Invalid NURBS definition');
    }
  }
  final int degree;
  final List<Vector3> points;
  final List<double> weights, knots;
  @override
  ({double min, double max}) get domain =>
      (min: knots[degree], max: knots[points.length]);
  @override
  Vector3 evaluate(double t) {
    final homogeneous = BSplineCurve3(
      degree,
      List.generate(
        points.length,
        (i) => Vector3(
          points[i].x * weights[i],
          points[i].y * weights[i],
          points[i].z * weights[i],
        ),
      ),
      knots,
    ).evaluate(t);
    final weight = BSplineCurve3(
      degree,
      List.generate(points.length, (i) => Vector3(weights[i], 0, 0)),
      knots,
    ).evaluate(t).x;
    if (weight.abs() < 1e-14) {
      throw StateError('Singular NURBS weight');
    }
    return homogeneous / weight;
  }

  @override
  Vector3 derivative(double t) {
    final h = math.max(1e-7, (domain.max - domain.min) * 1e-6);
    return (evaluate(t + h) - evaluate(t - h)) / (2 * h);
  }
}
