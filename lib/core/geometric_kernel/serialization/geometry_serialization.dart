import '../geometry/vectors.dart';

class GeometrySerialization {
  const GeometrySerialization();
  Map<String, dynamic> vector3(Vector3 v) => {
    'type': 'vector3',
    'version': 1,
    'value': v.toJson(),
  };
  Vector3 vector3From(Map<String, dynamic> json) =>
      Vector3.fromJson(json['value'] as List);
}
