abstract interface class EngineeringDNA {
  String get kind;
  String get hash;
  Map<String, dynamic> get components;
}

class StandardEngineeringDNA implements EngineeringDNA {
  const StandardEngineeringDNA(this.kind, this.hash, this.components);
  @override
  final String kind, hash;
  @override
  final Map<String, dynamic> components;
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'hash': hash,
    'components': components,
  };
  factory StandardEngineeringDNA.create(
    String kind,
    Map<String, dynamic> components,
  ) {
    final canonical = components.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final raw =
        '$kind:${canonical.map((e) => '${e.key}=${e.value}').join('|')}';
    final hash = raw.codeUnits
        .fold<int>(17, (a, b) => 37 * a + b)
        .toUnsigned(32)
        .toRadixString(16);
    return StandardEngineeringDNA(kind, hash, Map.unmodifiable(components));
  }
}
