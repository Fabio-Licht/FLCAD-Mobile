import 'engineering_envelope.dart';
import 'schema_registry.dart';

class MigrationEngine {
  const MigrationEngine(this.registry);
  final SchemaRegistry registry;
  EngineeringEnvelope migrate(
    EngineeringEnvelope envelope, {
    int? targetVersion,
  }) {
    final schema = registry.resolve(envelope.schema);
    final target = targetVersion ?? schema.currentVersion;
    if (envelope.version == target) {
      registry.validate(envelope.schema, envelope.payload);
      return envelope;
    }
    return EngineeringEnvelope(
      schema: envelope.schema,
      version: target,
      projectId: envelope.projectId,
      payload: registry.migrate(
        envelope.schema,
        envelope.version,
        envelope.payload,
        targetVersion: target,
      ),
      createdAt: envelope.createdAt,
    );
  }
}
