# Serialization Audit

`EngineeringEnvelope` standardizes schema, integer version, project ID, UTC creation time and payload. Existing domain JSON remains readable for compatibility. New formats must use envelopes; migration readers should accept legacy documents and write the newest schema atomically.
