typedef SchemaValidator = Iterable<String> Function(Map<String, dynamic> value);
typedef SchemaMigration =
    Map<String, dynamic> Function(Map<String, dynamic> value);

class EngineeringSchema {
  const EngineeringSchema({
    required this.name,
    required this.currentVersion,
    required this.validator,
    this.minimumReadableVersion = 1,
  });
  final String name;
  final int currentVersion, minimumReadableVersion;
  final SchemaValidator validator;
}

class SchemaValidationException implements Exception {
  const SchemaValidationException(this.schema, this.errors);
  final String schema;
  final List<String> errors;
  @override
  String toString() => 'Invalid $schema: ${errors.join(', ')}';
}

class SchemaRegistry {
  final Map<String, EngineeringSchema> _schemas = {};
  final Map<String, Map<int, SchemaMigration>> _migrations = {};

  void register(EngineeringSchema schema) {
    if (_schemas.containsKey(schema.name)) {
      throw StateError('Schema ${schema.name} already registered');
    }
    _schemas[schema.name] = schema;
  }

  void registerMigration(
    String schema,
    int fromVersion,
    SchemaMigration migration,
  ) {
    if (fromVersion < 1) throw ArgumentError.value(fromVersion, 'fromVersion');
    _migrations.putIfAbsent(schema, () => {})[fromVersion] = migration;
  }

  EngineeringSchema resolve(String name) =>
      _schemas[name] ?? (throw StateError('Schema $name is not registered'));
  bool canRead(String name, int version) {
    final schema = _schemas[name];
    return schema != null &&
        version >= schema.minimumReadableVersion &&
        (version <= schema.currentVersion ||
            version == schema.currentVersion + 1);
  }

  void validate(String name, Map<String, dynamic> value) {
    final errors = resolve(name).validator(value).toList(growable: false);
    if (errors.isNotEmpty) {
      throw SchemaValidationException(name, errors);
    }
  }

  Iterable<EngineeringSchema> get schemas => _schemas.values;

  Map<String, dynamic> migrate(
    String name,
    int fromVersion,
    Map<String, dynamic> value, {
    int? targetVersion,
  }) {
    final schema = resolve(name),
        target = targetVersion ?? schema.currentVersion;
    if (fromVersion > target) {
      throw StateError('Downgrade migrations are not supported');
    }
    var current = Map<String, dynamic>.from(value);
    for (var version = fromVersion; version < target; version++) {
      final migration = _migrations[name]?[version];
      if (migration == null) {
        throw StateError('Missing $name migration $version -> ${version + 1}');
      }
      current = migration(Map<String, dynamic>.from(current));
    }
    validate(name, current);
    return current;
  }
}
