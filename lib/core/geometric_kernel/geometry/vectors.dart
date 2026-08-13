import 'dart:math' as math;
import '../precision/precision.dart';

class Vector2 {
  const Vector2(this.x, this.y);
  final double x, y;
  Vector2 operator +(Vector2 o) => Vector2(x + o.x, y + o.y);
  Vector2 operator -(Vector2 o) => Vector2(x - o.x, y - o.y);
  Vector2 operator *(double s) => Vector2(x * s, y * s);
  Vector2 operator /(double s) => Vector2(x / s, y / s);
  double dot(Vector2 o) => x * o.x + y * o.y;
  double cross(Vector2 o) => x * o.y - y * o.x;
  double get length => math.sqrt(dot(this));
  Vector2 get normalized => length == 0 ? this : this / length;
  bool near(Vector2 o, Tolerance t) => t.close(x, o.x) && t.close(y, o.y);
  List<double> toJson() => [x, y];
}

class Vector3 {
  const Vector3(this.x, this.y, this.z);
  final double x, y, z;
  static const zero = Vector3(0, 0, 0);
  Vector3 operator +(Vector3 o) => Vector3(x + o.x, y + o.y, z + o.z);
  Vector3 operator -(Vector3 o) => Vector3(x - o.x, y - o.y, z - o.z);
  Vector3 operator -() => Vector3(-x, -y, -z);
  Vector3 operator *(double s) => Vector3(x * s, y * s, z * s);
  Vector3 operator /(double s) => Vector3(x / s, y / s, z / s);
  double dot(Vector3 o) => x * o.x + y * o.y + z * o.z;
  Vector3 cross(Vector3 o) =>
      Vector3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get lengthSquared => dot(this);
  double get length => math.sqrt(lengthSquared);
  Vector3 get normalized => length == 0 ? this : this / length;
  double distanceTo(Vector3 o) => (this - o).length;
  bool near(Vector3 o, Tolerance t) =>
      t.close(x, o.x) && t.close(y, o.y) && t.close(z, o.z);
  List<double> toJson() => [x, y, z];
  factory Vector3.fromJson(List<dynamic> v) => Vector3(
    (v[0] as num).toDouble(),
    (v[1] as num).toDouble(),
    (v[2] as num).toDouble(),
  );
}

class Vector4 {
  const Vector4(this.x, this.y, this.z, this.w);
  final double x, y, z, w;
  Vector4 operator +(Vector4 o) => Vector4(x + o.x, y + o.y, z + o.z, w + o.w);
  Vector4 operator *(double s) => Vector4(x * s, y * s, z * s, w * s);
  double dot(Vector4 o) => x * o.x + y * o.y + z * o.z + w * o.w;
  List<double> toJson() => [x, y, z, w];
}
