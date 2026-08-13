# Feature History

Every create, rebuild, failure, unavailable operation, validation and healing event has a typed history action. A feature records ID, inputs, output, dependencies, user, timestamp, revision, parameters, build time and preserved human decisions.

Replay uses successful create and rebuild revisions. Persistent history is appended under `CAD/History/events.jsonl`.

