# Guided Workflow Engine

`GuidedWorkflowEngine` is a deterministic dependency state machine. A step can start only when ready. Completion unlocks exactly its successor, updates aggregate progress and appends a replayable timeline entry. Locked, blocked and failed states are explicit; no unavailable CAD operation is treated as completed geometry.
