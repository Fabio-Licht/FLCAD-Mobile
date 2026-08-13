# Schema Registry

`SchemaRegistry` owns schema identity, current/minimum readable versions and validation. Serializers should register at the composition root and validate before materialization. One-version-forward recognition is available for inspection; unknown future payloads are never silently interpreted.
