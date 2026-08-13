enum FELType {
  mesh,
  region,
  point,
  vector,
  plane,
  axis,
  cylinder,
  cone,
  sphere,
  surface,
  sketch,
  curve,
  solid,
  project,
  selection,
  number,
  boolean,
  string,
  color,
  matrix,
  transformation,
  voidType,
  dynamicType,
}

class FELValue {
  const FELValue(this.type, this.value);
  final FELType type;
  final Object? value;
  static const voidValue = FELValue(FELType.voidType, null);
}
