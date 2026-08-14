enum FeatureParameterMode { normal, reference, locked, driven, driving }

class FeatureParameter {
  FeatureParameter({
    required this.name,
    this.value,
    this.expression,
    this.unit = '',
    this.defaultValue,
    this.mode = FeatureParameterMode.normal,
  });
  final String name, unit;
  num? value, defaultValue;
  String? expression;
  FeatureParameterMode mode;
  final List<String> diagnostics = [];
  bool get locked => mode == FeatureParameterMode.locked;
}

class FeatureParameterSet {
  final Map<String, FeatureParameter> parameters = {};
  void define(FeatureParameter parameter) {
    if (parameters.containsKey(parameter.name)) {
      throw StateError('Duplicate parameter: ${parameter.name}');
    }
    parameters[parameter.name] = parameter;
  }

  void set(String name, num value) {
    final p =
        parameters[name] ?? (throw StateError('Unknown parameter: $name'));
    if (p.locked) throw StateError('Locked parameter: $name');
    p.value = value;
  }

  num? resolve(String name, [Set<String>? stack]) {
    final p = parameters[name];
    if (p == null) return null;
    if (p.expression == null) return p.value ?? p.defaultValue;
    final seen = stack ?? <String>{};
    if (!seen.add(name)) {
      throw StateError('Circular parameter expression: $name');
    }
    final expression = p.expression!.trim();
    final direct = parameters[expression];
    if (direct != null) return resolve(expression, seen);
    final literal = num.tryParse(expression);
    if (literal != null) return literal;
    p.diagnostics.add(
      'Formula requires future equation evaluator: $expression',
    );
    return null;
  }

  List<String> validate() {
    final issues = <String>[];
    for (final p in parameters.values) {
      try {
        if (resolve(p.name) == null) {
          issues.add('Unresolved parameter: ${p.name}');
        }
      } catch (e) {
        issues.add(e.toString());
      }
    }
    return issues;
  }

  Map<String, dynamic> toJson() => parameters.map(
    (k, p) => MapEntry(k, {
      'value': p.value,
      'expression': p.expression,
      'unit': p.unit,
      'defaultValue': p.defaultValue,
      'mode': p.mode.name,
      'diagnostics': p.diagnostics,
    }),
  );
}
