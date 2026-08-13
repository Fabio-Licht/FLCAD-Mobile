# Migration Engine

Migrations are deterministic, sequential functions registered by source version. Missing links fail explicitly. Downgrades are unsupported. `MigrationEngine` preserves envelope project ownership and creation time while upgrading payload and version.
