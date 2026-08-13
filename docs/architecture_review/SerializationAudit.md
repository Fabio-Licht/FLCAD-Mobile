# Serialization Audit

## Current state

Three serialization styles coexist:

1. `EngineeringEnvelope` with explicit schema and integer version.
2. New foundation serializers with top-level schema/version (`flcad.arei.snapshot`, Engineering Knowledge, Cognition and Autonomous Reconstruction).
3. Domain entity JSON where `version` is entity revision, not schema version (Reference, Sketch, Surface), or no version exists (Smart Regions).

Project, reconstruction and AI repositories commonly use temporary-file write followed by rename, which is a positive atomicity pattern. Several `fromJson` methods provide defaults for newly optional fields, offering limited backward compatibility.

## Gaps

- No central schema registry or migration chain.
- No declared minimum reader/maximum writer version.
- Unknown enum values generally throw through `byName`/`firstWhere`, preventing forward compatibility.
- No golden corpus tests spanning historic payload versions.
- New Cognition/Autonomous serializers encode but do not decode.
- Integrity checksums and corruption recovery are absent.

## Required standard

All persisted roots should use `EngineeringEnvelope` semantics: stable schema ID, schema version, project ID, creation time and payload. Entity revision must remain a separate field. Readers should reject unsupported major versions with typed errors and preserve unknown metadata. A migration registry and golden fixtures should precede V1 data guarantees.
