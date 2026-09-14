import 'dart:convert';

/// Durable root appearance. Geometry is already canonical millimeters; the
/// declared scale is provenance and must never be applied a second time.
final class StepAppearanceManifest {
  StepAppearanceManifest({
    required this.name,
    required this.declaredUnit,
    required this.declaredMetersPerUnit,
    required this.resolvedMetersPerUnit,
    required List<double>? linearRgb,
    this.compatibilitySourceSha256,
  }) : linearRgb = linearRgb == null
           ? null
           : List.unmodifiable(linearRgb.map((v) => v == 0 ? 0.0 : v)) {
    _validate(toJson());
  }

  final String name, declaredUnit;
  final double declaredMetersPerUnit, resolvedMetersPerUnit;
  final List<double>? linearRgb;
  final String? compatibilitySourceSha256;
  bool get usedCompatibility => compatibilitySourceSha256 != null;
  static const normalizationRules = [
    'si-unit-solid-angle-order',
    'si-unit-solid-angle-derived',
  ];
  bool get hasColor => linearRgb != null;

  Map<String, dynamic> toJson() => {
    'schema': 'flcad.step-appearance',
    'version': usedCompatibility ? 2 : 1,
    'name': name,
    'declaredUnit': declaredUnit,
    'declaredMetersPerUnit': declaredMetersPerUnit,
    'resolvedUnit': 'mm',
    'resolvedMetersPerUnit': resolvedMetersPerUnit,
    'hasColor': hasColor,
    'colorSpace': 'linear-srgb',
    'rootRgb': linearRgb,
    'alpha': hasColor ? 1.0 : null,
    if (usedCompatibility)
      'compatibility': {
        'version': 1,
        'sourceSha256': compatibilitySourceSha256,
        'normalizations': [
          for (final rule in normalizationRules) {'rule': rule, 'version': 1},
        ],
      },
  };

  /// Fixed field order and canonical numeric values, independent of input order.
  List<int> encode() => utf8.encode(jsonEncode(toJson()));

  factory StepAppearanceManifest.fromJson(Map<String, dynamic> json) {
    _validate(json);
    return StepAppearanceManifest(
      name: json['name'] as String,
      declaredUnit: json['declaredUnit'] as String,
      declaredMetersPerUnit: (json['declaredMetersPerUnit'] as num).toDouble(),
      resolvedMetersPerUnit: (json['resolvedMetersPerUnit'] as num).toDouble(),
      linearRgb: json['rootRgb'] == null
          ? null
          : (json['rootRgb'] as List)
                .map((v) => (v as num).toDouble())
                .toList(),
      compatibilitySourceSha256: json['version'] == 2
          ? (json['compatibility'] as Map)['sourceSha256'] as String
          : null,
    );
  }

  static void _validate(Map<String, dynamic> json) {
    const keys = {
      'schema',
      'version',
      'name',
      'declaredUnit',
      'declaredMetersPerUnit',
      'resolvedUnit',
      'resolvedMetersPerUnit',
      'hasColor',
      'colorSpace',
      'rootRgb',
      'alpha',
    };
    bool text(Object? value, int max, {bool empty = false}) =>
        value is String &&
        (empty || value.isNotEmpty) &&
        utf8.encode(value).length <= max &&
        !value.runes.any(
          (r) => r < 32 || r == 127 || (r >= 0xd800 && r <= 0xdfff),
        );
    final scale = json['declaredMetersPerUnit'];
    final rgb = json['rootRgb'];
    final compatibility = json['compatibility'];
    final isCompatible = json['version'] == 2;
    bool validCompatibility() {
      if (compatibility is! Map ||
          compatibility.length != 3 ||
          compatibility['version'] is! int ||
          compatibility['version'] != 1 ||
          compatibility['sourceSha256'] is! String ||
          !RegExp(
            r'^[0-9a-f]{64}$',
          ).hasMatch(compatibility['sourceSha256'] as String)) {
        return false;
      }
      final rules = compatibility['normalizations'];
      if (rules is! List || rules.length != normalizationRules.length) {
        return false;
      }
      for (var i = 0; i < rules.length; i++) {
        final rule = rules[i];
        if (rule is! Map ||
            rule.length != 2 ||
            rule['rule'] != normalizationRules[i] ||
            rule['version'] is! int ||
            rule['version'] != 1) {
          return false;
        }
      }
      return true;
    }

    if (json.length != keys.length + (isCompatible ? 1 : 0) ||
        json.keys.any(
          (k) => !keys.contains(k) && !(isCompatible && k == 'compatibility'),
        ) ||
        json['schema'] != 'flcad.step-appearance' ||
        json['version'] is! int ||
        (json['version'] != 1 && !isCompatible) ||
        (isCompatible && !validCompatibility()) ||
        !text(json['name'], 4096, empty: true) ||
        !text(json['declaredUnit'], 256) ||
        scale is! num ||
        !scale.isFinite ||
        scale <= 0 ||
        json['resolvedUnit'] != 'mm' ||
        json['resolvedMetersPerUnit'] != 0.001 ||
        json['hasColor'] is! bool ||
        json['colorSpace'] != 'linear-srgb' ||
        (json['hasColor'] == false
            ? rgb != null || json['alpha'] != null
            : rgb is! List ||
                  rgb.length != 3 ||
                  rgb.any((v) => v is! num || !v.isFinite || v < 0 || v > 1) ||
                  json['alpha'] != 1.0)) {
      throw const FormatException('Invalid STEP appearance manifest');
    }
  }
}

/// Core validation is shared by runtime construction and document decoding.
void validateManagedStepAssets(Map<String, dynamic> json) {
  const keys = {
    'schema',
    'version',
    'sourceFormat',
    'meshOnly',
    'shapeAssetId',
    'shapeSha256',
    'displayMeshAssetId',
    'displayMeshSha256',
    'appearanceManifestAssetId',
    'appearanceManifestSha256',
  };
  if (json.length != keys.length ||
      json.keys.any((k) => !keys.contains(k)) ||
      json['schema'] != 'flcad.managed-step-assets' ||
      json['version'] is! int ||
      json['version'] != 1 ||
      json['sourceFormat'] != 'step' ||
      json['meshOnly'] != false) {
    throw const FormatException('Invalid managed STEP asset reference');
  }
  final ids = <String>{};
  for (final prefix in ['shape', 'displayMesh', 'appearanceManifest']) {
    final id = json['${prefix}AssetId'];
    final hash = json['${prefix}Sha256'];
    if (id is! Map ||
        id.length != 3 ||
        id['schema'] != 'flcad.geometry-asset' ||
        id['version'] is! int ||
        id['version'] != 1 ||
        id['id'] is! String ||
        !RegExp(r'^ga1_[0-9a-f]{32}$').hasMatch(id['id'] as String) ||
        !ids.add(id['id'] as String) ||
        hash is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const FormatException('Invalid managed STEP asset identity/hash');
    }
  }
}
