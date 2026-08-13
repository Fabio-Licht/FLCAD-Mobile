# ADR-015: Separate reconstruction planning from CAD execution

Status: Accepted

## Decision

ERI consumes UERS evidence and produces an immutable, progressive DAG. EDE owns strategy decisions; ERI owns plan decomposition and supervision. Existing Autonomous Reconstruction remains a compatible lower-level planning source. No ERI API returns geometric entities.

## Consequences

Plans can be reviewed, compared and incrementally rebuilt before a future CAD kernel exists. Human overrides are durable workflow state. The Solid node is explicitly blocked, preventing planning metadata from being mistaken for executed geometry.
